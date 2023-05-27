oci_reference?=new-oci-img
dnf_bootstrap_image?=registry.fedoraproject.org/fedora:38
dnf_bootstrap_repo?=http://openkoji.iscas.ac.cn/kojifiles/repos/f38-build-side-42-init-devel/latest/riscv64
dnf_bootstrap_releasever?=38
arch?=riscv64

hello:
	@echo "Hello, World! Run make plct-fedora-38-rv64 to build an oci image."

make-temp:
	-mkdir ./temp

dnf-podman-bootstrap:
	$(MAKE) script-dnf-rootfs
	$(MAKE) script-repo
	$(MAKE) script-end
	podman run --rm -i --tty -v ./temp:/mnt/temp:z $(dnf_bootstrap_image) /bin/bash #/mnt/temp/bootstrap.sh

script-dnf-rootfs: make-temp
	# Dnf Install Rootfs
	@echo dnf --installroot /mnt/temp/rootfs \\ >> ./temp/bootstrap.sh
	@echo --repofrompath bootstrap-repo,$(dnf_bootstrap_repo) --repo bootstrap-repo \\ >> ./temp/bootstrap.sh
	@echo --nodocs --setopt=install_weak_deps=False -x systemd -x dbus -x polkit \\ >> ./temp/bootstrap.sh
	@echo --forcearch $(arch) --nogpgcheck --releasever $(dnf_bootstrap_releasever) \\  >> ./temp/bootstrap.sh
	@echo -y \\  >> ./temp/bootstrap.sh
	@echo install dnf5 vim-minimal >> ./temp/bootstrap.sh

script-repo: make-temp
	# Change default repo
	@echo dnf install \'dnf-command\(config-manager\)\' -y >> ./temp/bootstrap.sh
	@echo dnf --installroot /mnt/temp/rootfs config-manager --set-disabled \"\*\" >> ./temp/bootstrap.sh
	@echo dnf --installroot /mnt/temp/rootfs config-manager  --add-repo /mnt/temp/bootstrap.repo >> ./temp/bootstrap.sh
	@echo [bootstrap] > ./temp/bootstrap.repo
	@echo name=Bootstrapping Repo >> ./temp/bootstrap.repo
	@echo baseurl=$(dnf_bootstrap_repo) >> ./temp/bootstrap.repo
	@echo gpgcheck=0 >> ./temp/bootstrap.repo

script-end: make-temp
	# Packup
	@echo tar czf /mnt/temp/rootfs.tar.gz --directory=/mnt/temp/rootfs . >> ./temp/bootstrap.sh

podman-import:
ifeq ($(strip $(rootfs_archive)),)
	@echo "rootfs_archive is empty, image will not be built"
	exit 1
endif
	podman import --change 'CMD ["/bin/bash"]'  --arch=$(arch) $(rootfs_archive) $(oci_reference)

dnf-based-oci-image:
	$(MAKE) dnf-podman-bootstrap
	$(MAKE) rootfs_archive=./temp/rootfs.tar.gz podman-import

plct-fedora-38-rv64:
	$(MAKE) dnf-based-oci-image

clean:
	-podman run --rm -i --tty -v ./temp:/mnt/temp:z $(dnf_bootstrap_image) /bin/rm -rf /mnt/temp
	rm -rf ./temp

