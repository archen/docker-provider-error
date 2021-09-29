# Example of provider failure

The terraform provider https://registry.terraform.io/providers/kreuzwerker/docker/2.15.0 applies different file permissions in the resultant image(s) when `COPY` or `ADD` instructions are used in Dockerfiles depending on the type of `resource` building the image.

`docker_image` resources exhibit the same behavior as running the `docker build` command from the command line: both preserve the local filesystem's permissions flags.

`docker_registry_image` resources strip the permissions from the copied/added files making them inaccessible to all users but `root` without adding a permissions repair step.

## Try it out
You will need to be authenticated to ECR locally for this to work. The terraform creates a single ECR repository and attempts to build/upload 3 images; only two of them will work.
```bash
terraform init
terraform apply -auto-approve
```
At this point, `docker_registry_image.image_sync["broke-registry"]` resource should have failed on the `RUN cat testfile` step.

To clean up, you may need to run `terraform destroy -auto-approve` twice consecutively.
