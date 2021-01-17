CONF_DIR=config
RANDFILE=$(CONF_DIR)/.rnd
CA_ROOT=ca
ADMIN_ROOT=admin

.PHONY: all

all: ca

clean: clean-ca

# Initialize rand file
init:
ifeq (,$(wildcard $(RANDFILE)))
	    dd if=/dev/urandom of=$(RANDFILE) bs=256 count=1
endif

ca: $(CONF_DIR)/ca.cnf init
	mkdir -p $(CA_ROOT)
	openssl req -x509 -config $(CONF_DIR)/ca.cnf -rand $(RANDFILE) -new -sha256 -nodes -out $(CA_ROOT)/ca.crt -keyout $(CA_ROOT)/ca.key

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
	@openssl ca -config $(CONF_DIR)/ca.cnf \
		       -batch \
		       -rand $(RANDFILE) \
			   -outdir $(ADMIN_ROOT) \
			   -extensions signing_req \
			   -cert $(CA_ROOT)/ca.crt \
			   -out $(ADMIN_ROOT)/admin.crt \
			   -infiles $(ADMIN_ROOT)/admin.csr

clean-ca:
	rm $(CA_ROOT)/*.crt || /bin/true
	rm $(CA_ROOT)/*.key || /bin/true
	rm $(CA_ROOT)/*.csr || /bin/true

clean-admin:
	rm $(ADMIN_ROOT)/*.crt || /bin/true
	rm $(ADMIN_ROOT)/*.key || /bin/true
	rm $(ADMIN_ROOT)/*.csr || /bin/true
