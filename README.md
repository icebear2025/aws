### Solutions (Terraform)

- 먼저 `init`을 해줍니다.
```sh
terraform init
```

- `plan` 명령어를 통해 현재 코드의 오류부분을 체크합니다.
```sh
terraform plan
```

- 오류가 없다면 `apply` 명령어를 통해 인프라를 생성해줍니다.
```sh
terraform apply -auto-approve
```
