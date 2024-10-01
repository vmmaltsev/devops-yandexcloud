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

Виртуальная сеть успешно создана и готова к установке кластера Kubernetes.

## Запуск и тестирование команд Terraform

Необходимо запустить команды `terraform apply` и `terraform destroy` для проверки автоматизированного создания и удаления инфраструктуры. Если используется Terraform Cloud, рекомендуется также провести проверку через его web-интерфейс.

### Выполнение команды `terraform destroy`

Команда `terraform destroy` используется для удаления всех созданных ресурсов:

```bash
$ terraform destroy
```

Пример результата выполнения:

```text
yandex_vpc_network.k8s_network: Refreshing state... [id=enprth280e6u25aer1af]
yandex_vpc_subnet.k8s_subnet[1]: Refreshing state... [id=e2lqui71tp7mstadl9em]
yandex_vpc_subnet.k8s_subnet[0]: Refreshing state... [id=e9b4106odg55o30nsjmp]
yandex_vpc_subnet.k8s_subnet[2]: Refreshing state... [id=fl8ikg4anbku5ihqmr41]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # yandex_vpc_network.k8s_network will be destroyed
  - resource "yandex_vpc_network" "k8s_network" {
      - description = "VPC network for k8s"
      - name        = "k8s-network"
      - subnet_ids  = [
          "e2lqui71tp7mstadl9em",
          "e9b4106odg55o30nsjmp",
          "fl8ikg4anbku5ihqmr41",
        ]
    }

  # yandex_vpc_subnet.k8s_subnet[0] will be destroyed
  - resource "yandex_vpc_subnet" "k8s_subnet" {
      - description = "Subnet A in zone ru-central1-a"
      - name        = "k8s-subnet-a"
      - v4_cidr_blocks = [
          "10.10.1.0/24",
        ]
      - zone = "ru-central1-a"
    }

  # yandex_vpc_subnet.k8s_subnet[1] will be destroyed
  - resource "yandex_vpc_subnet" "k8s_subnet" {
      - description = "Subnet B in zone ru-central1-b"
      - name        = "k8s-subnet-b"
      - v4_cidr_blocks = [
          "10.10.2.0/24",
        ]
      - zone = "ru-central1-b"
    }

  # yandex_vpc_subnet.k8s_subnet[2] will be destroyed
  - resource "yandex_vpc_subnet" "k8s_subnet" {
      - description = "Subnet D in zone ru-central1-d"
      - name        = "k8s-subnet-d"
      - v4_cidr_blocks = [
          "10.10.3.0/24",
        ]
      - zone = "ru-central1-d"
    }

Plan: 0 to add, 0 to change, 4 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```

Результат удаления ресурсов:

```text
yandex_vpc_subnet.k8s_subnet[1]: Destroying... [id=e2lqui71tp7mstadl9em]
yandex_vpc_subnet.k8s_subnet[2]: Destroying... [id=fl8ikg4anbku5ihqmr41]
yandex_vpc_subnet.k8s_subnet[0]: Destroying... [id=e9b4106odg55o30nsjmp]
yandex_vpc_subnet.k8s_subnet[2]: Destruction complete after 3s
yandex_vpc_subnet.k8s_subnet[0]: Destruction complete after 4s
yandex_vpc_subnet.k8s_subnet[1]: Destruction complete after 4s
yandex_vpc_network.k8s_network: Destroying... [id=enprth280e6u25aer1af]
yandex_vpc_network.k8s_network: Destruction complete after 1s

Destroy complete! Resources: 4 destroyed.
```

### Выполнение команды `terraform apply`

Для повторного создания ресурсов выполните команду `terraform apply`:

```bash
$ terraform apply
```

Пример выполнения команды:

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
      + v4_cidr_blocks = [
          "10.10.1.0/24",
        ]
      + zone = "ru-central1-a"
    }

  # yandex_vpc_subnet.k8s_subnet[1] will be created
  + resource "yandex_vpc_subnet" "k8s_subnet" {
      + description = "Subnet B in zone ru-central1-b"
      + name        = "k8s-subnet-b"
      + v4_cidr_blocks = [
          "10.10.2.0/24",
        ]
      + zone = "ru-central1-b"
    }

  # yandex_vpc_subnet.k8s_subnet[2] will be created
  + resource "yandex_vpc_subnet" "k8s_subnet" {
      + description = "Subnet D in zone ru-central1-d"
      + name        = "k8s-subnet-d"
      + v4_cidr_blocks = [
          "10.10.3.0/24",
        ]
      + zone = "ru-central1-d"
    }

Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Enter a value: yes
```

Результат применения изменений:

```text
yandex_vpc_network.k8s_network: Creating...
yandex_vpc_network.k8s_network: Creation complete after 6s [id=enp6tls07rh09188utio]
yandex_vpc_subnet.k8s_subnet[0]: Creating...
yandex_vpc_subnet.k8s_subnet[2]: Creating...
yandex_vpc_subnet.k8s_subnet[1]: Creating...
yandex_vpc_subnet.k8s_subnet[2]: Creation complete after 1s [id=fl8pf9dp9g358ve88rcu]
yandex_vpc_subnet.k8s_subnet[0]: Creation complete after 2s [id=e9bthgmal15598e1spqh]
yandex_vpc_subnet.k8s_subnet[1]: Creation complete after 3s [id=e2lgg5tehc2t39jurc37]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

Команды `terraform apply` и `terraform destroy` успешно протестированы. Ресурсы могут быть автоматически созданы и удалены с помощью Terraform, обеспечивая эффективное управление инфраструктурой в Яндекс.Облаке.

### Итог этапа создания облачной инфраструктуры

В результате выполнения этого этапа была успешно создана базовая облачная инфраструктура в Яндекс.Облаке, включая сервисный аккаунт, S3 bucket для хранения состояния Terraform и сеть VPC с подсетями в разных зонах доступности. Инфраструктура готова для дальнейшей установки и настройки Kubernetes кластера, и все действия могут быть выполнены с использованием Terraform без дополнительных ручных вмешательств.

# Создание Kubernetes кластера

На данном этапе необходимо создать Kubernetes кластер на базе ранее созданной инфраструктуры. Требуется обеспечить доступ к ресурсам кластера из Интернета.

## Два варианта развертывания кластера

### Рекомендуемый вариант: Самостоятельная установка Kubernetes кластера

1. **Подготовка виртуальных машин с помощью Terraform**:
   - Создайте как минимум 3 виртуальных машины в **Compute Cloud** для развертывания кластера. Тип виртуальных машин выбирайте исходя из производительности и стоимости.
   - В случае необходимости внесения изменений в конфигурацию инстансов, используйте Terraform для автоматизации процесса.

2. **Использование Ansible для настройки Kubernetes**:
   - Подготовьте **Ansible** конфигурации для автоматизации развертывания Kubernetes на созданных виртуальных машинах.
   - Один из инструментов, который можно использовать, — **Kubespray**.

3. **Деплой Kubernetes на виртуальных машинах**:
   - Разверните Kubernetes кластер с помощью подготовленных ранее Ansible конфигураций.
   - Если в процессе настройки обнаружится нехватка ресурсов, создавайте дополнительные с помощью Terraform.

### Альтернативный вариант: Использование Yandex Managed Service for Kubernetes

1. **Создание регионального Kubernetes кластера**:
   - Используйте **Terraform** для создания регионального мастера Kubernetes, размещая ноды в 3 различных подсетях.

2. **Настройка Node Group**:
   - Настройте node group через ресурс **Terraform Kubernetes** для развертывания worker нод.

## Ожидаемые результаты

- Работоспособный Kubernetes кластер с доступом из Интернета.
- Данные для доступа к кластеру находятся в файле `~/.kube/config`.
- Команда `kubectl get pods --all-namespaces` выполняется без ошибок, отображая статус всех подов во всех пространствах имен.

# Описание действий

## Альтернативный вариант: Использование Yandex Managed Service for Kubernetes (MSK)

### Шаги по созданию Kubernetes кластера в MSK

1. **Создание регионального Kubernetes кластера с помощью Terraform**:
   - Воспользуйтесь **Yandex Managed Service for Kubernetes (MSK)** для быстрого развертывания и управления Kubernetes кластером без ручной настройки виртуальных машин.
   - Убедитесь, что у вас настроена конфигурация Terraform и подготовлен S3 bucket для хранения состояния Terraform, как описано в предыдущих этапах.

Для создания кластера необходимо расширить код Terraform, который был создан при создании VPC на предыдущем этапе. Код представлен в папке **terraform_main**.

```bash
vmaltsev@DESKTOP-V2R3TOO:~/devops-yandexcloud/terraform_main$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
...
```

После проведения проверки конфигурации необходимо применить изменения.

```bash
vmaltsev@DESKTOP-V2R3TOO:~/devops-yandexcloud/terraform_main$ terraform apply
...
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

2. **Настройка регионального мастера Kubernetes**:
   - Используя **Terraform**, создайте региональный мастер для Kubernetes. При этом мастер будет распределен в различных зонах доступности для обеспечения высокой доступности кластера.
   - Распределите ноды мастера по трем различным подсетям (availability zones), чтобы минимизировать риски отказа и увеличить надежность.

Действия выполнены на предыдущем шаге.

3. **Создание и настройка группы узлов (Node Group)**:
   - Определите группы узлов (Node Group) — набор виртуальных машин, которые будут выступать worker-нодами в кластере. Каждая группа узлов может быть настроена с разными параметрами производительности и масштабирования.
   - Используйте ресурсы **Terraform** для настройки групп узлов, задавая параметры автоматического масштабирования и количество нод в каждой группе.

Действия выполнены на предыдущем шаге.

4. **Настройка доступа к кластеру**:
   - После успешного развертывания кластера проверьте файл `~/.kube/config`. Этот файл содержит информацию для доступа к вашему кластеру Kubernetes.
   - Настройте `kubectl`, чтобы подключиться к кластеру и выполнять команды по управлению ресурсами кластера.

Для получения доступа к кластеру необходимо использовать Yandex CLI.

```bash
vmaltsev@DESKTOP-V2R3TOO:~/devops-yandexcloud/terraform_main$ yc managed-kubernetes cluster list
+----------------------+----------------------+---------------------+---------+---------+-----------------------+-------------------+
|          ID          |         NAME         |     CREATED AT      | HEALTH  | STATUS  |   EXTERNAL ENDPOINT   | INTERNAL ENDPOINT |
+----------------------+----------------------+---------------------+---------+---------+-----------------------+-------------------+
| catr5akt6pe1or1s5id0 | regional-k8s-cluster | 2024-09-30 11:16:11 | HEALTHY | RUNNING | https://84.201.170.85 | https://10.10.1.3 |
+----------------------+----------------------+---------------------+---------+---------+-----------------------+-------------------+

vmaltsev@DESKTOP-V2R3TOO:~/devops-yandexcloud/terraform_main$ yc managed-kubernetes cluster get-credentials catr5akt6pe1or1s5id0 --external

Context 'yc-regional-k8s-cluster' was added as default to kubeconfig '/home/vmaltsev/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/vmaltsev/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'test-project'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
```

Файл с конфигом создан в папке `/home/vmaltsev/.kube`.

5. **Проверка состояния кластера**:
   - После настройки доступа к кластеру убедитесь, что все компоненты работают корректно. Выполните команду:
     ```bash
     kubectl get pods --all-namespaces
     ```
   - Эта команда должна вернуть список всех подов (pods) во всех пространствах имен (namespaces) кластера, отображая их статус без ошибок.

При выполнении команды получается следующий вывод:

```bash
vmaltsev@DESKTOP-V2R3TOO:~/devops-yandexcloud/terraform_main$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                   READY   STATUS    RESTARTS   AGE
kube-system   coredns-5d4bf4fdc8-9rncd               1/1     Running   0          5m57s
kube-system   coredns-5d4bf4fdc8-hvbj4               1/1     Running   0          10m
kube-system   ip-masq-agent-5g2wm                    1/1     Running   0          6m28s
kube-system   ip-masq-agent-nlr2r                    1/1     Running   0          6m29s
kube-system   ip-masq-agent-xvctw                    1/1     Running   0          6m36s
kube-system   kube-dns-autoscaler-74d99dd8dc-lmtcc   1/1     Running   0          10m
kube-system   kube-proxy-8c8f6                       1/1     Running   0          6m36s
kube-system   kube-proxy-9dnwf                       1/1     Running   0          6m29s
kube-system   kube-proxy-vkcbf                       1/1     Running   0          6m28s
kube-system   metrics-server-6b5df79959-bhpzm        2/2     Running   0          5m47s
kube-system   npd-v0.8.0-2pmpc                       1/1     Running   0          6m36s
kube-system   npd-v0.8.0-kmqt9                       1/1     Running   0          6m29s
kube-system   npd-v0.8.0-vnr46                       1/1     Running   0          6m28s
kube-system   yc-disk-csi-node-v2-6qlcw              6/6     Running   0          6m36s
kube-system   yc-disk-csi-node-v2-bjgsx              6/6     Running   0          6m29s
kube-system   yc-disk-csi-node-v2-mxpmh              6/6     Running   0          6m28s
```

## Итог этапа создания кластера Kubernetes

В результате выполнения этого этапа был успешно создан региональный кластер.


# Создание тестового приложения

## Описание этапа
Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение, разрабатываемое вашей компанией. Приложение должно быть простым и легко развертываться в Kubernetes.

## Способы подготовки

### Рекомендуемый вариант
1. **Создание репозитория для тестового приложения**:
   - Создайте новый git-репозиторий для приложения.
   - Добавьте в него простой конфигурационный файл `nginx` для раздачи статических данных (например, HTML-файла).

2. **Подготовка Dockerfile**:
   - Создайте `Dockerfile` для сборки Docker-образа приложения.
   - Описывайте инструкции для создания образа на основе `nginx` и копирования статических файлов.

### Альтернативный вариант
- Используйте любой другой код, главное требование — наличие самостоятельно написанного `Dockerfile`.

## Ожидаемый результат

1. **Git-репозиторий с тестовым приложением и `Dockerfile`**:
   - Репозиторий содержит все необходимые файлы для сборки и запуска приложения.

2. **Docker-образ в контейнерном реестре**:
   - Docker-образ собран и загружен в контейнерный реестр (`DockerHub` или `Yandex Container Registry`).

## Описание действий

### Шаг 1: Создание репозитория и конфигурационного файла `nginx`
- Репозиторий: [GitHub - vmmaltsev/test_app](https://github.com/vmmaltsev/test_app.git).

### Шаг 2: Подготовка `Dockerfile`
**HTML (index.html):**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Nginx Application</title>
    <meta name="description" content="This is a simple test application running on Nginx.">
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            text-align: center;
            background-color: #f9f9f9;
        }
        h1 { color: #333; }
        p { color: #555; }
    </style>
</head>
<body>
    <header>
        <h1>Welcome</h1>
    </header>
    <main>
        <p>This is a simple test application running on Nginx.</p>
    </main>
    <footer>
        <p>&copy; 2024 Test Application</p>
    </footer>
</body>
</html>
```

**Nginx конфигурация (nginx.conf):**

```nginx
events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    server {
        listen 80 default_server;
        server_name localhost;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";

        location / {
            root /usr/share/nginx/html;
            index index.html;
            location ~ /\. { deny all; }
        }

        error_page 404 /404.html;
        location = /404.html { internal; }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html { internal; }
    }
}
```

**Dockerfile:**

```Dockerfile
FROM nginx:1.21-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

EXPOSE 80

ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

CMD ["nginx", "-g", "daemon off;"]
```

### Шаг 3: Сборка и загрузка Docker-образа
1. Создайте реестр на DockerHub, например, `maltsevvm/test_app`.

2. Соберите и отправьте образ в DockerHub:
    ```bash
    docker build -t maltsevvm/test_app:latest .
    docker push maltsevvm/test_app:latest
    ```

3. Проверьте, что образ успешно создан:
    ```bash
    docker images
    ```
    Ожидаемый результат:
    ```
    REPOSITORY                 TAG       IMAGE ID       CREATED              SIZE
    maltsevvm/test_app         latest    <IMAGE_ID>     <TIME_AGO>           23.4MB
    ```

4. Отправьте образ в репозиторий DockerHub:
    ```bash
    docker push maltsevvm/test_app:latest
    ```

## Заключение
На этом этапе был успешно создан git-репозиторий с тестовым приложением, а также DockerHub-репозиторий с загруженным Docker-образом приложения.

![DockerHub](https://github.com/vmmaltsev/screenshot/blob/main/Screenshot_183.png)

![GitHub](https://github.com/vmmaltsev/screenshot/blob/main/Screenshot_184.png)