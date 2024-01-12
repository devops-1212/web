:topic: ansible-playbook-to-install-jenkins-with-docker

Плейбук Ansible для установки Jenkins с docker
==============================================

**Задача:** установить Jenkins с docker используя плейбук Ansible.

|

Ansible playbook будет выполнять следующие шаги:

* **Первый шаг:** запустим ``apt update`` для получения информации о доступных версиях пакетов.
* **Второй шаг:** установим docker.
* **Третий шаг:** запустим jenkins контейнер.

Для удобства, все шаги мы вынесем в различные ansible roles. Первый шаг будет system role, второй шаг - docker role, третий шаг - jenkins role.


system role
+++++++++++

Файл ``roles/system/tasks/main.yml``:

.. code-block:: yaml

    - name: Update and upgrade apt packages
      become: true
      become_user: root
      apt:
        upgrade: "yes"
        update_cache: true


Здесь мы используем `ansible apt module <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html>`_ с параметрами: 

* ``update_cache: true`` - указывает ansible выполнить ``apt-get update``.
* ``upgrade: "yes"`` - запускается ``aptitude safe-upgrade``.

docker role
+++++++++++

Файл ``roles/docker/tasks/main.yml``:

.. code-block:: yaml

    - name: Install docker package
      become: true
      become_user: root 
      package: name={{ item }} state=present
      with_items:
       - docker.io
    
    - name: Start Docker Service
      become: true
      become_user: root
      service: name=docker state=started enabled=yes


`Package module <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html>`_ устанавливает docker.io пакет.

`Service module <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html>`_ запускает docker сервис и добавляет его в автозапуск. 

jenkins role
++++++++++++

Файл ``roles/jenkins/tasks/main.yml``:

.. code-block:: yaml

    - name: Create jenkins home directory
      become: true
      become_user: root 
      ansible.builtin.file:
        path: /opt/jenkins
        state: directory
        owner: '1000'
        group: '1000'
        recurse: true
    
    - name: Install python3-docker package
      become: true
      become_user: root 
      package: name={{ item }} state=present
      with_items:
       - python3-docker
    
    - name: Create jenkins container
      become: true
      become_user: root 
      docker_container:
        container_default_behavior: no_defaults
        name: jenkins
        image: jenkins/jenkins:jdk17
        state: started
        ports:
          - '0.0.0.0:8080:8080'
          - '0.0.0.0:50000:50000'
        restart_policy: always
        volumes:
          - /opt/jenkins:/var/jenkins_home


`ansible.builtin.file module <https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html>`_ создаёт ``/opt/jenkins`` директорию. Директория будет использоваться для хранения всей конфигурации jenkins и jenkins jobs. Мы её будем подключать в jenkins контейнер.

Package устанавливает python3-docker deb пакет - `docker_container module <https://docs.ansible.com/ansible/latest/collections/community/docker/docker_container_module.html>`_ использует python3-docker для запуска jenkins контейнера.

Docker_container запускает jenkins контейнер. Параметры:

* ``container_default_behavior: no_defaults`` - в разных версиях параметры модуля имеют разные значения по умолчанию. Значение ``no_defaults`` указывает не использовать старые значения по умолчанию.

* ``ports`` - проброс портов с Jenkins контейнера на хост.

* ``restart_policy: always`` - политика перезапуска контейнера, применяемая при окончании его работы. 

* ``volumes`` - список томов для монтирования в контейнер. 

Playbook 
++++++++

Файл ``jenkins.yml``:

.. code-block:: yaml

    - name: Install jenkins
      hosts: all
      remote_user: ubuntu

      roles:
        - system
        - docker
        - jenkins

* ``hosts: all`` - правила будут выполняться для всех хостов.
* ``remote_user: ubuntu`` - учетная запись пользователя для SSH-соединения.
* ``roles`` - список roles для выполнения.

Запуск
++++++

Для запуска playbook мы должны указать inventory файл - список хостов для запуска. Например:

.. code-block:: ini

    [all]
    10.5.0.162  

Запускаем playbook:

.. code-block:: shell

    $ ansible-playbook -i hosts jenkins.yml 

    PLAY [Install jenkins] ************************************************************************************************

    TASK [Gathering Facts] ************************************************************************************************
    ok: [10.5.0.162]

    TASK [system : Update and upgrade apt packages] ***********************************************************************
    changed: [10.5.0.162]

    TASK [docker : Install docker package] ********************************************************************************
    changed: [10.5.0.162] => (item=docker.io)

    TASK [docker : Start Docker Service] **********************************************************************************
    ok: [10.5.0.162]

    TASK [jenkins : Create jenkins home directory] ************************************************************************
    changed: [10.5.0.162]

    TASK [jenkins : Install python3-docker package] ***********************************************************************
    changed: [10.5.0.162] => (item=python3-docker)

    TASK [jenkins : Create jenkins container] *****************************************************************************
    changed: [10.5.0.162]

    PLAY RECAP ************************************************************************************************************
    10.5.0.162                 : ok=7    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
