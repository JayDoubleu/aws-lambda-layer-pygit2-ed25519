# aws-lambda-layer-pygit2-ed25519
AWS Lambda layer with pre-compiled pygit2/libgit2 and ed25519 support.

## Build instructions:
```
git clone https://github.com/JayDoubleu/aws-lambda-layer-pygit2-ed25519
cd aws-lambda-layer-pygit2-ed25519
```
Build:
```
docker build  -t pygit2-lambda-layer .
#docker build -t pygit2-lambda-layer . # defaults to "3.8.0" if no PYTHON_VERSION argument specified.
docker build --build-arg PYTHON_VERSION="3.8.5" -t pygit2-lambda-layer .
docker run -v $(pwd):/tmp/lambda_layer_ready -it pygit2-lambda-layer sh copy_zip.sh
```
You should see pygit2_lambda_layer.zip in your current directory

Publish layer with:

```
 aws lambda publish-layer-version --layer-name pygit2_lambda_layer --zip-file fileb://pygit2_lambda_layer.zip
```

To import pygit2 in lambda you need to import libraries first as shown in example below:

```
import pygit2_libs
import pygit2
```

If you don't want to build it yourself you can grab zip file from releases.
