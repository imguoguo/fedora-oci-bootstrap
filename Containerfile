FROM registry.fedoraproject.org/fedora:41 AS builder

ARG dnf_bootstrap_releasever=42
ARG dnf_bootstrap_repo=http://openkoji.iscas.ac.cn/kojifiles/repos/f${dnf_bootstrap_releasever}-build/latest/riscv64
ARG arch=riscv64

RUN dnf --installroot=/rootfs --releasever=${dnf_bootstrap_releasever} \
    --setopt=install_weak_deps=False --nodocs --forcearch=${arch} --nogpgcheck \
    --repofrompath=bootstrap-repo,${dnf_bootstrap_repo} -x systemd -x dbus -x polkit \
    install -y dnf5 vim-minimal && \
    dnf clean all --installroot=/rootfs

FROM --platform=linux/riscv64 scratch AS final

COPY --from=builder /rootfs/ /

CMD ["/bin/bash"]