cd "$(git rev-parse --show-toplevel)"

docker build -f docker/falco/Dockerfile -t "kronostechnologies/falco:$(git describe --tags)" .
