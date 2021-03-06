DOCKER_IMAGE_NAME=theia_ide
DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:latest

build:
	docker build \
		-t ${DOCKER_IMAGE_TAG} \
		-f Dockerfile .

clean:
	docker image rm ${DOCKER_IMAGE_TAG}

run:
	docker run -it --rm -p 3000:3000 ${DOCKER_IMAGE_TAG}
