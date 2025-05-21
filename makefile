dnf_bootstrap_image?=registry.fedoraproject.org/fedora:41
dnf_bootstrap_releasever?=42
oci_reference?=docker.io/fedorariscv/base:$(dnf_bootstrap_releasever)
dnf_bootstrap_repo?=http://openkoji.iscas.ac.cn/kojifiles/repos/f$(dnf_bootstrap_releasever)-build/latest/riscv64
container_toolkit?=podman
arch?=riscv64

hello:
	@echo "Hello, World! Run make plct-fedora-38-rv64 to build an oci image."

make-temp:
	-mkdir ./temp

dnf-container-bootstrap:
	$(MAKE) script-dnf-rootfs
	$(MAKE) script-end
	$(container_toolkit) run --rm -i --tty -v ./temp:/mnt/temp:z $(dnf_bootstrap_image) /bin/bash /mnt/temp/bootstrap.sh

script-dnf-rootfs: make-temp
	# Dnf Install Rootfs
	@echo dnf --installroot /mnt/temp/rootfs \\ >> ./temp/bootstrap.sh
	@echo --repofrompath bootstrap-repo,$(dnf_bootstrap_repo) --repo bootstrap-repo \\ >> ./temp/bootstrap.sh
	@echo --nodocs --setopt=install_weak_deps=False -x systemd -x dbus -x polkit \\ >> ./temp/bootstrap.sh
	@echo --forcearch $(arch) --nogpgcheck --releasever $(dnf_bootstrap_releasever) \\  >> ./temp/bootstrap.sh
	@echo -y \\  >> ./temp/bootstrap.sh
	@echo install dnf5 vim-minimal >> ./temp/bootstrap.sh

script-end: make-temp
	# Packup
	@echo tar czf /mnt/temp/rootfs.tar.gz --directory=/mnt/temp/rootfs . >> ./temp/bootstrap.sh

container-import:
ifeq ($(strip $(rootfs_archive)),)
	@echo "rootfs_archive is empty, image will not be built"
	exit 1
endif
	$(container_toolkit) import --change 'CMD ["/bin/bash"]'  --arch=$(arch) $(rootfs_archive) $(oci_reference)

dnf-based-oci-image:
	$(MAKE) dnf-container-bootstrap
	$(MAKE) rootfs_archive=./temp/rootfs.tar.gz container-import

plct-fedora-42-rv64:
	$(MAKE) dnf-based-oci-image

clean:
	-$(container_toolkit) run --rm -i --tty -v ./temp:/mnt/temp:z $(dnf_bootstrap_image) /bin/rm -rf /mnt/temp
	rm -rf ./temp

