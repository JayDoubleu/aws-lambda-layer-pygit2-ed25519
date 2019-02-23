FROM centos
# Install dependecies
RUN yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y groupinstall 'Development Tools'
RUN yum -y install libffi-devel libcurl-devel cmake autoreconf git curl http-parser-devel libgpg-error-devel zlib-devel perl-core lksctp-tools-devel zip
# Compile OpenSSL 1.1.1 (ed25519 support)
RUN curl -o /tmp/openssl.tar.gz https://www.openssl.org/source/openssl-1.1.1.tar.gz
RUN tar -xvf /tmp/openssl.tar.gz -C /tmp/
WORKDIR "/tmp/openssl-1.1.1"
ADD files/ca-dir.patch .
RUN patch -p0 -i ca-dir.patch
RUN ./Configure \
        --prefix=/usr --openssldir=/etc/pki/tls enable-ec_nistp_64_gcc_128 \
	zlib enable-camellia enable-seed enable-rfc3779 enable-sctp \
	enable-cms enable-md2 enable-rc5 enable-ssl3 enable-ssl3-method \
	enable-weak-ssl-ciphers \
	no-mdc2 no-ec2m no-sm2 no-sm4 \
	shared linux-x86_64

RUN make && make install
RUN /bin/cp -rf /usr/lib/* /lib64/ && ldconfig

# Compile libssh2 (ed25519 support)
RUN git clone https://github.com/libssh2/libssh2.git /tmp/libssh2 && cd /tmp/libssh2 && git reset --hard cf13c9925c42e6e9eeaa6525f43aedc9ed2df9ec
RUN mkdir /tmp/libssh2/build
RUN ls
WORKDIR "/tmp/libssh2/build"
RUN cmake .. && cmake -DBUILD_SHARED_LIBS=ON --build . && cmake --build . --target install
RUN /bin/cp -rf /usr/local/lib64/* /lib64/ && ldconfig

# Compile libgit2 (required for pygit2 + ed25519 support)
RUN git clone https://github.com/libgit2/libgit2.git /tmp/libgit2 && cd /tmp/libgit2 && git reset --hard 7321cff05df927c8d00755ef21289ec00d125c9c
RUN mkdir /tmp/libgit2/build
WORKDIR "/tmp/libgit2/build"
RUN cmake .. && cmake -DBUILD_SHARED_LIBS=ON --build . && cmake --build . --target install
RUN /bin/cp -rf /usr/local/lib/* /lib64/ && ldconfig

# Create virtualenv and install pygit2 files
RUN mkdir /tmp/pygit2
WORKDIR "/tmp/pygit2"
RUN mkdir /tmp/static_libs/
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep "libhttp_parser\.\|libcrypto\|libssl\.\|libssh2\|librt\-\|libcurl"|grep ".so$"|while read i; do readlink -f "$i";done|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep librtmp|grep \.so|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep libgcrypt|grep \.so|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep libcrypto\.so\.10|grep \.so|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep libgit2|grep \.so|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep libgpg-error\.|grep \.so$|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep libgnutls|grep \.so|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep libc\.so|grep \.so|while read i; do cp $i /tmp/static_libs/;done
RUN ldconfig -p|awk -F '=>' '{print $2}'|sed  "s/ //g"|grep libfipschec|grep \.so|while read i; do cp $i /tmp/static_libs/;done

# Install python 3.7
RUN mkdir /tmp/python_build
WORKDIR /tmp/python_build
RUN curl -O  https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
RUN tar -xvf Python-3.7.2.tgz
RUN cd Python-3.7.2 && ./configure --enable-optimizations && make altinstall


RUN mkdir /tmp/venv
WORKDIR /tmp/venv
RUN python3.7 -m venv .
RUN source bin/activate && pip install pygit2
RUN find . -name "libffi*"|grep \.so|while read i; do cp $i /tmp/static_libs/;done

WORKDIR /tmp/static_libs/
ADD files/create_test_py.sh .
RUN chmod +x create_test_py.sh && sh create_test_py.sh

RUN mkdir -p /tmp/lambda_layer/python/lib/python3.7/site-packages/
WORKDIR /tmp/lambda_layer
RUN mv /tmp/venv/lib/python3.7/site-packages/* /tmp/lambda_layer/python/lib/python3.7/site-packages/
RUN mv /tmp/static_libs/* /tmp/lambda_layer/python/lib/python3.7/site-packages/
RUN rm -f python/lib/python3.7/site-packages/create_test_py.sh
RUN zip -r ../pygit2_lambda_layer.zip .

FROM centos
WORKDIR "/tmp/lambda_layer"
COPY --from=0 /tmp/pygit2_lambda_layer.zip .
RUN ls
ADD files/copy_zip.sh /bin/
RUN chmod +x /bin/copy_zip.sh
