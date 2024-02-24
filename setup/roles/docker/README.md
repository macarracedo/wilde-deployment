docker
=========

A minimal role to install docker and docker-compose on Debian

Requirements
------------

None

Role Variables
--------------

None

Dependencies
------------

None

Example Playbook
----------------

```yaml
- hosts: all
  tasks:
   - name: Install docker on all servers
     include_role: docker

- hosts: leader
  tasks:
   - name: Initialize swarm on leader
     include_role: docker_leader

- hosts: workers
  tasks:
   - name: Add workers to swarm cluster
     include_role: docker_worker

- hosts: managers
  tasks:
   - name: Add managers to swarm cluster
     include_role: docker_manager
````

License
-------

BSD

Author Information
------------------

Implemented by José Ramón Méndez Reboredo. Please note that this is part of the materials for the subject AAS on the MSC on Computer Science (University of Vigo)
