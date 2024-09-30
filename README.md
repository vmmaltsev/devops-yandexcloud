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

## Создание сети VPC

Создать виртуальную частную сеть (VPC) с несколькими подсетями в разных зонах доступности (availability zones). Проверить, что сеть корректно сконфигурирована и готова к использованию Kubernetes кластером.

## Запуск и тестирование команд Terraform

Запустить команды `terraform apply` и `terraform destroy`, чтобы убедиться в автоматизированном создании и удалении инфраструктуры без ручных доработок. Если используется Terraform Cloud, провести проверку через его web-интерфейс.

## Оптимизация инфраструктуры под бюджет

При планировании ресурсов учитывать ограничения бюджета. Для self-hosted Kubernetes использовать минимальное количество ресурсов для виртуальных машин, при этом обеспечивая их работоспособность. В обоих случаях использовать прерываемые виртуальные машины для узлов worker nodes.
