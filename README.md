# Fedora OCI Bootstrap

Using fedora image and dnf to bootstrap an OCI image for rpm-based distribution.

## Usage

```
make [OPTIONS] dnf-based-oci-image
```

Example for Fedora riscv64 with Open Koji repo from PLCT Lab:

```
make \
    dnf_bootstrap_repo?=http://openkoji.iscas.ac.cn/kojifiles/repos/f38-build-side-42-init-devel/latest/riscv64 \
    dnf_bootstrap_releasever?=38 \
    arch?=riscv64 \
    oci_reference?=your-new-image \
    dnf-based-oci-image
```

Calling `make dnf-based-oci-image` without any options will create a riscv64 image for Fedora 38.
