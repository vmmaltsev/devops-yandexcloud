# Цели

1. **Подготовить облачную инфраструктуру** на базе облачного провайдера Яндекс.Облако.
2. **Запустить и сконфигурировать Kubernetes кластер**.
3. **Установить и настроить систему мониторинга**.
4. **Настроить и автоматизировать сборку тестового приложения** с использованием Docker-контейнеров.
5. **Настроить CI** для автоматической сборки и тестирования.
6. **Настроить CD** для автоматического развёртывания приложения.

# Этапы выполнения

## Создание облачной инфраструктуры
Для начала необходимо подготовить облачную инфраструктуру в Яндекс.Облаке при помощи Terraform.

### Особенности выполнения:

- Бюджет купона ограничен, что следует учитывать при проектировании инфраструктуры и использовании ресурсов.
- Для облачного Kubernetes используйте региональный мастер (неотказоустойчивый).
- Для self-hosted Kubernetes минимизируйте ресурсы ВМ и долю ЦПУ.
- В обоих вариантах используйте прерываемые ВМ для worker nodes.

## Предварительная подготовка к установке и запуску Kubernetes кластера

1. **Создайте сервисный аккаунт**, который будет использоваться Terraform для работы с инфраструктурой с необходимыми правами (не используйте права суперпользователя).
2. **Подготовьте backend для Terraform**:
   - **Рекомендуемый вариант**: S3 bucket в Яндекс.Облаке (создание бакета через Terraform).
   - **Альтернативный вариант**: Terraform Cloud.
3. **Создайте VPC с подсетями** в разных зонах доступности.
4. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
5. Если используется **Terraform Cloud** в качестве backend, убедитесь, что применение изменений успешно проходит через web-интерфейс Terraform Cloud.

## Ожидаемые результаты:

- Terraform сконфигурирован, и создание инфраструктуры возможно без дополнительных ручных действий.
- Полученная конфигурация инфраструктуры является предварительной и может изменяться в ходе дальнейшего выполнения задания.



# Описание действий

## Подготовка аккаунта и прав

Создать сервисный аккаунт с правами для работы с Terraform. Проверить, что у аккаунта есть все необходимые права для управления ресурсами Яндекс.Облака, но не использовать права суперпользователя.

### Установка Yandex CLI

Для создания сервисного аккаунта используйте инструмент командной строки **Yandex CLI**. Установить его можно с помощью команды:

```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

### Инициализация Yandex CLI

После установки начните настройку профиля CLI с помощью команды:

```bash
yc init
```

#### Процесс инициализации

Во время инициализации необходимо будет ввести OAuth-токен из сервиса Яндекс ID и создать новый профиль. Пример процесса инициализации:

```bash
$ yc init
Welcome! This command will take you through the configuration process.
Pick desired action:
[1] Re-initialize this profile 'default' with new settings 
[2] Create a new profile
Please enter your numeric choice: 2
Enter profile name. Names start with a lower case letter and contain only lower case letters a-z, digits 0-9, and hyphens '-': test-project
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=1a69******2fb in order to obtain OAuth token.
Please enter OAuth token: y0_AgAAAABkZ6G*******ujmQpGYqjMnKPPvUc
You have one cloud available: 'cloud-nphne-xquks5er' (id = b1gn***q4s6). It is going to be used by default.
Please choose folder to use:
[1] main (id = b1gjgdh******120m)
[2] Create a new folder
Please enter your numeric choice: 2
Please enter a folder name: test-project
Your current folder has been set to 'test-project' (id = b1gv***muo).
Do you want to configure a default Compute zone? [Y/n] y
Which zone do you want to use as a profile default?
[1] ru-central1-a
[2] ru-central1-b
[3] ru-central1-c
[4] ru-central1-d
[5] Don't set default zone
Please enter your numeric choice: 1
Your profile default Compute zone has been set to 'ru-central1-a'.
```

### Создание сервисного аккаунта

После инициализации необходимо создать сервисный аккаунт:

```bash
$ yc iam service-account create --name test-sa
done (1s)
id: ajeho0q***qc77d
folder_id: b1gve****lmuo
created_at: "2024-09-30T06:20:50.632372561Z"
name: test-sa
```

### Назначение прав сервисному аккаунту

Назначьте необходимые права созданному сервисному аккаунту в текущем профиле:

```bash
$ yc resource-manager folder add-access-binding b1g******uo --role editor --subject serviceAccount:ajeho********c77d
done (2s)
effective_deltas:
  - action: ADD
    access_binding:
      role_id: editor
      subject:
        id: ajeho0q********c77d
        type: serviceAccount
```

### Создание ключа для Terraform

Создайте ключ доступа для Terraform, который привязан к созданному сервисному аккаунту и профилю:

```bash
$ yc iam key create   --service-account-id ajeho********77d   --folder-name test-project   --output key_terraform.json
id: aje4**********bsgj
service_account_id: aje**************c77d
created_at: "2024-09-30T06:51:46.225440417Z"
key_algorithm: RSA_2048
```

В результате этих действий будет создан JSON-файл с ключом, который используется для управления инфраструктурой через Terraform.

## Настройка Terraform backend

Создать S3 bucket для хранения состояния Terraform либо настроить Terraform Cloud для сохранения состояния. Важно проверить, что backend корректно сохраняет состояние и обеспечивает доступ к нему.

Для создания бакета используются конфигурации Terraform, которые размещены в папке `terraform_backend` данного репозитория.

```bash
$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.129.0"...
- Installing yandex-cloud/yandex v0.129.0...
- Installed yandex-cloud/yandex v0.129.0 (self-signed, key ID E40F590B50BB8E40)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Затем проверьте валидность конфигураций:

```bash
$ terraform validate
Success! The configuration is valid.
```

И создайте план развертывания:

```bash
$ terraform plan
```

Пример ожидаемого результата:

```text
Terraform will perform the following actions:

  # yandex_iam_service_account.sa will be created
  + resource "yandex_iam_service_account" "sa" {
      + folder_id = "b1gve******glmuo"
      + name      = "terraform-bucket-test"
    }

  # yandex_storage_bucket.bucket will be created
  + resource "yandex_storage_bucket" "bucket" {
      + bucket    = "bucket-vmaltsev-test"
    }

Plan: 4 to add, 0 to change, 0 to destroy.
```

После подтверждения будет создан бакет:

```bash
$ terraform apply
Do you want to perform these actions?
  Enter a value: yes

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

service_account_access_key = <sensitive>
service_account_secret_key = <sensitive>
```

## Получение ключей для Terraform backend

Для использования этого бакета в качестве backend Terraform необходимо получить ключи, сохраненные в outputs:

```bash
$ terraform output -json
{
  "service_account_access_key": {
    "sensitive": true,
    "value": "YCA************CKXp"
  },
  "service_account_secret_key": {
    "sensitive": true,
    "value": "YCMr1P************m5bec"
  }
}
```


## Создание сети VPC

Создание виртуальной частной сети (VPC) с несколькими подсетями в разных зонах доступности (availability zones) позволяет разделить ресурсы и повысить надежность. Важно проверить, что сеть правильно сконфигурирована и готова к использованию Kubernetes кластером.

Для создания VPC используются конфигурации Terraform, которые размещены в папке `terraform_main` данного репозитория. Terrafom использует ранее настроенный backend, который размещен в S3 бакете.

### Инициализация Terraform

Перед началом работы необходимо инициализировать Terraform, чтобы он мог работать с конфигурациями и провайдерами:

```bash
$ terraform init
```

Результат инициализации:

```text
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching "0.129.0"...
- Installing yandex-cloud/yandex v0.129.0...
- Installed yandex-cloud/yandex v0.129.0 (self-signed, key ID E40F590B50BB8E40)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!
```

После успешной инициализации можно проверить корректность конфигураций:

```bash
$ terraform validate
```

Результат:

```text
Success! The configuration is valid.
```

### Планирование ресурсов VPC

Для предварительного просмотра изменений, которые будут внесены, выполните команду:

```bash
$ terraform plan
```

Пример результата выполнения команды `terraform plan`:

```text
Terraform will perform the following actions:

  # yandex_vpc_network.k8s_network will be created
  + resource "yandex_vpc_network" "k8s_network" {
      + description = "VPC network for k8s"
      + name        = "k8s-network"
    }

  # yandex_vpc_subnet.k8s_subnet[0] will be created
  + resource "yandex_vpc_subnet" "k8s_subnet" {
      + description = "Subnet A in zone ru-central1-a"
      + name        = "k8s-subnet-a"
      + v4_cidr_blocks = ["10.10.1.0/24"]
      + zone        = "ru-central1-a"
    }

  # yandex_vpc_subnet.k8s_subnet[1] will be created
  + resource "yandex_vpc_subnet" "k8s_subnet" {
      + description = "Subnet B in zone ru-central1-b"
      + name        = "k8s-subnet-b"
      + v4_cidr_blocks = ["10.10.2.0/24"]
      + zone        = "ru-central1-b"
    }

  # yandex_vpc_subnet.k8s_subnet[2] will be created
  + resource "yandex_vpc_subnet" "k8s_subnet" {
      + description = "Subnet D in zone ru-central1-d"
      + name        = "k8s-subnet-d"
      + v4_cidr_blocks = ["10.10.3.0/24"]
      + zone        = "ru-central1-d"
    }

Plan: 4 to add, 0 to change, 0 to destroy.
```

### Применение изменений

Чтобы создать сеть и подсети на основе конфигурации Terraform, выполните команду:

```bash
$ terraform apply
```

После запуска Terraform спросит подтверждение на выполнение изменений. Введите `yes` для подтверждения:

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Результат выполнения:

```text
yandex_vpc_network.k8s_network: Creating...
yandex_vpc_network.k8s_network: Creation complete after 9s [id=enprth280e6u25aer1af]
yandex_vpc_subnet.k8s_subnet[1]: Creating...
yandex_vpc_subnet.k8s_subnet[2]: Creating...
yandex_vpc_subnet.k8s_subnet[0]: Creating...
yandex_vpc_subnet.k8s_subnet[1]: Creation complete after 1s [id=e2lqui71tp7mstadl9em]
yandex_vpc_subnet.k8s_subnet[2]: Creation complete after 1s [id=fl8ikg4anbku5ihqmr41]
yandex_vpc_subnet.k8s_subnet[0]: Creation complete after 2s [id=e9b4106odg55o30nsjmp]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

После применения изменений будет создана одна сеть и три подсети в разных зонах доступности.

Виртуальная сеть успешно создана и готова к установке класnера Kubernetes.

## Запуск и тестирование команд Terraform

Запустить команды `terraform apply` и `terraform destroy`, чтобы убедиться в автоматизированном создании и удалении инфраструктуры без ручных доработок. Если используется Terraform Cloud, провести проверку через его web-интерфейс.

## Оптимизация инфраструктуры под бюджет

При планировании ресурсов учитывать ограничения бюджета. Для self-hosted Kubernetes использовать минимальное количество ресурсов для виртуальных машин, при этом обеспечивая их работоспособность. В обоих случаях использовать прерываемые виртуальные машины для узлов worker nodes.
