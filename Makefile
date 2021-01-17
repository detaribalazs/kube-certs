CONF_DIR=config
RANDFILE=$(CONF_DIR)/.rnd
CA_ROOT=ca
ADMIN_ROOT=admin

.PHONY: all

all: ca admin

clean: clean-ca clean-admin

init: rand-init ca-init

# Initialize rand file
rand-init:
ifeq (,$(wildcard $(RANDFILE)))
	dd if=/dev/urandom of=$(RANDFILE) bs=256 count=1
endif

#Initialize CA
ca-init: index-init 

# Initialize CA index
index-init:
ifeq (,$(wildcard $(CA_ROOT)/index.txt))
	@touch $(CA_ROOT)/index.txt	
	@touch $(CA_ROOT)/index.txt.attr
endif
	@echo "CA index initialized"

# Initialize CA serial
serial-init:
ifeq (,$(wildcard $(CA_ROOT)/index.txt))
	@touch $(CA_ROOT)/serial
endif
	@echo "CA serial initialized"

ca-init: index-init serial-init

# Create self signed CA certificate
ca: $(CONF_DIR)/ca.cnf init
	mkdir -p $(CA_ROOT)
	openssl req -x509 -config $(CONF_DIR)/ca.cnf -rand $(RANDFILE) -new -sha256 -nodes -out $(CA_ROOT)/ca.crt -keyout $(CA_ROOT)/ca.key

# Generate CSR for admin user
admin-csr: $(CONF_DIR)/client.cnf init
	mkdir -p $(ADMIN_ROOT)
	@openssl req -config $(CONF_DIR)/client.cnf \
				-rand $(RANDFILE) \
	            -new \
	            -sha256 \
				-nodes \
				-subj "/CN=admin/O=system:masters/C=HU/L=Budapest/ST=Budapest" \
				-out $(ADMIN_ROOT)/admin.csr \
				-keyout $(ADMIN_ROOT)/admin.key

admin: $(CONF_DIR)/client.cnf admin-csr ca
	echo admin > $(CA_ROOT)/serial
	@openssl ca -config $(CONF_DIR)/ca.cnf \
		       -batch \
		       -rand $(RANDFILE) \
			   -outdir $(ADMIN_ROOT) \
			   -extensions signing_req \
			   -cert $(CA_ROOT)/ca.crt \
			   -out $(ADMIN_ROOT)/admin.crt \
			   -infiles $(ADMIN_ROOT)/admin.csr

clean-index:
	@-rm $(CA_ROOT)/index.txt

clean-serial:
	@-rm $(CA_ROOT)/serial

clean-ca: clean-index clean-serial
	@-rm $(CA_ROOT)/*.crt
	@-rm $(CA_ROOT)/*.key
	@-rm $(CA_ROOT)/*.csr
	@-rm $(CA_ROOT)/index.txt

clean-admin:
	@-rm $(ADMIN_ROOT)/*.crt
	@-rm $(ADMIN_ROOT)/*.key
	@-rm $(ADMIN_ROOT)/*.csr
