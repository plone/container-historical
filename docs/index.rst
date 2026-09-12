===============
Plone On Docker
===============

.. toctree::
   :hidden:


   usage/index
   container-images/custom
   data/index
   scaling/index

Community maintained `Plone <https://plone.org>`_ Images for `Docker <https://docker.com>`_.


Introduction
============

`Plone Docker Images <https://hub.docker.com/_/plone/>`_ are maintained by
the `Plone Community <https://plone.org>`_.

.. note::

   Because of the way how `Docker, Inc. <https://docker.com>`_ handles 'official images', sometimes the releases
   are lagging behind.

   You can get always the latest releases from our own `repository <https://github.com/plone/container-historical>`_ on Docker Hub.


These images are a compromise between the `best practices for writing Dockerfiles <https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/>`_
and `installing Plone using the Unified UNIX Installer <https://docs.plone.org/manage/installing/installation.html>`_.

.. warning::

   Please **do not** copy one of the examples of this documentation and use it in
   production !

   If you want to use it in production, you need to have solid knowledge about
   Docker and hosting.

   **Running Plone as a microservice is only suited if you update and deploy your Plone
   microservice on a regular basis !**

Our images are excellent for test driving Plone, checking add-ons or as a base for
development/theming.
