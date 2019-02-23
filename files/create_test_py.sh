cat <<EOF > pygit2_libs.py
venv = '/opt/python/lib/python3.6/site-packages/'
from ctypes import *
load_libffi = cdll.LoadLibrary (venv + '$(ls libffi*)')
load_libhttp_parser = cdll.LoadLibrary (venv + '$(ls libhttp_parser*)')
load_libcrypto = cdll.LoadLibrary(venv + '$(ls libcrypto.so\.1\.*)')
load_libgpg_error = cdll.LoadLibrary(venv + '$(ls libgpg\-error*)')
load_libgcrypt = cdll.LoadLibrary(venv + '$(ls libgcrypt*)')
load_libssl = cdll.LoadLibrary(venv + '$(ls libssl*)')
load_libssh2 = cdll.LoadLibrary(venv + '$(ls libssh2*)')
load_libgit2 = cdll.LoadLibrary(venv + '$(ls libgit2\.so\.*)')
EOF
