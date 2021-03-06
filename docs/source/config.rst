.. _config:


Holland Config Files
====================

By default, Holland's configuration files reside in /etc/holland. The main
configuration file is holland.conf, however there are a number of other 
configuration files for configuring default settings for providers and for
configuring backup sets.

Each configuration file has one ore more sections, defined by square
brackets Underneath each section, one or more configuration option
can be specified. These options are in a standard "option = value" format.
Comments are prefixed by the # sign.

Note that many settings have default values and, as a result, can either
be commented out or omitted entirely.

holland.conf - main config
--------------------------

The main configuration file (usually /etc/holland/holland.conf) defines
both global settings as well as the active backup sets. It is divided into
two sections :ref:`[holland]<holland-config>` and :ref:`[logging]<logging-config>`. 

.. _holland-config:

[holland]
^^^^^^^^^

.. _holland-config-plugin_dirs:

.. describe:: plugin_dirs = [directory1],[directory2],...,[directoryN]

    Defines where the plugins can be found. This can be a comma-separated 
    list but usually does not need to be modified. For most installations,
    this will usually be ``/usr/share/holland/plugins``.

.. deprecated:: 1.0.8

    This option is no longer required and can be ommitted. 
    
.. _holland-config-backup_directory:    
    
.. describe:: backup_directory = [directory]

    Top-level directory where backups are held. This is usually 
    ``/var/spool/holland``.
    
.. _holland-config-backupsets:

.. describe:: backupsets = [backupset1],[backupset2],...,[backupsetN]

    A comma-separated list of all the backup sets Holland should backup.
    Each backup set is defined in ``/etc/holland/backupsets/<name>.conf`` by
    default.
    
.. describe:: umask = [0000-7777]

    Sets the umask of the resulting backup files.
    
.. describe:: path = <directory1>:<directory2>:...:<directoryN>

    Defines a path for holland and its spawned processes.

.. _logging-config:
    
[logging]
^^^^^^^^^

.. describe:: filename = [path]/[filename]

    The log file itself.

.. describe:: level = [debug|info|warning|error|critical]

    Sets the verbosity of Holland's logging process. Available options are
    ``debug``, ``info``, ``warning``, ``error``, and ``critical``

Example
^^^^^^^

.. code-block:: ini

    ## Root holland config file
    [holland]

    ## Paths where holland plugins may be found.
    ## Can be comma separated
    plugin_dirs = /usr/share/holland/plugins

    ## Top level directory where backups are held
    backup_directory = /var/spool/holland

    ## List of enabled backup sets. Can be comma separated. 
    ## Read from <config_dir>/backupsets/<name>.conf
    # backupsets = example, traditional, parallel_backups, non_transactional
    backupsets = mydbbackup, pgdump-full, mysql-lvm-reportingdb

    # Define a umask for file generated by holland
    umask = 0007

    # Define a path for holland and its spawned processes
    path = /usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin

    [logging]
    ## where to write the log
    filename = /var/log/holland.log

    ## debug, info, warning, error, critical (case insensitive)
    level = info

Backup-Set Configs
------------------

Backup-Set configuration files largely inherit the configuration options of
the specified plugins. To define a provider plugin for the backup set, you
must put the following at the top of the backup set configuration file

.. code-block:: ini

    [holland:backup]
    plugin = <plugin>
    backups-to-keep = #
    estimated-size-factor = #

.. _holland-backup-config_options:

[holland:backup] Configuration Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. describe:: plugin = [provider plugin]

    This is the name of the provider that will be used for the backup-set.
    This is required in order for the backup-set to function.

.. describe:: backups-to-keep = #

    Specifies the number of backups to keep for a backup-set. 
    Defaults to retaining 1 backup.

.. describe:: estimated-size-factor = #

    Specifies the scale factor when Holland decides if there is enough
    free space to perform a backup.  The default is 1.0 and this number
    is multiplied against what each individual plugin reports its 
    estimated backup size when Holland is verifying sufficient free
    space for the backupset.

.. describe:: auto-purge-failures = [yes|no]

    Specifies whether to keep a failed backup or to automatically remove
    the backup directory.  By default this is on with the intention that
    whatever process is calling holland will retry when a backup fails. 
    This behavior can be disabled by setting auto-purge-failures = no when
    partial backups might be useful or when troubleshooting a backup failure.

.. describe:: purge-policy = [manual|before-backup|after-backup]

    Specifies when to run the purge routine on a backupset.  By default this is
    run after a new successful backup completes.  Up to ``backups-to-keep``
    backups will be retained including the most recent.

    ``purge-policy`` = ``before-backup`` will run the purge routine just before
    a new backup starts.  This will retain up to ``backups-to-keep`` backups
    before the new backup is even started allowing purging all previous
    backups if ``backups-to-keep`` is set to 0.  This behavior is useful if
    some other process is retaining backups off-server and disk space is at a
    premium.

    ``purge-policy`` = manual will never run the purge routine automatically.
    Either ``holland purge`` must be run externally or an explicit removal of
    desired backup directories can be done at some later time.

Hooks
"""""

.. describe:: before-backup-command = string

    Run a shell command before a backup starts.  This allows a command to 
    perform some action before the backup starts such as setting up an
    iptables rule (taking a mysql slave out of a load balancer) or aborting 
    the backup based on some external condition. 
    
    The backup will fail if this command exits with a non-zero status.

    .. versionadded:: 1.0.7

.. describe:: after-backup-command = string

    Run a shell command after a backup completes.  This allows a command to 
    perform some action when a backup completes successfully such as sending
    out a success notification.
    
    The backup will fail if this command exits with a non-zero status.

    .. versionadded:: 1.0.7

.. describe:: failed-backup-command = string

    Run a shell command if a backup starts.  This allows some command to 
    perform some action when a backup fails such as sending out a failure
    notification.

    The backup will fail if this command exits with a non-zero status.

    .. versionadded:: 1.0.7

For all hook commands, Holland will perform simple text substitution  
on the three parameters:

  * **hook**: The name of the hook being called (one of: ``before-backup-command``, ``after-backup-command``, ``failed-backup-command``)
  * **backupdir**: The path to the current backup directory (e.g. ``/var/spool/holland/mysqldump/YYYYmmdd_HHMMSS``)
  * **backupset**: The name of the backupset being run (e.g. ``mysql-lvm``)

For example

.. code-block:: ini
    
    [holland:backup]
    plugin = mysqldump
    before-backup-command = /usr/local/bin/my-custom-script --hook ${hook} --backupset ${backupset} --backupdir ${backupdir}
    after-backup-command = echo ${backupset} completed successfully.  Files are in ${backupdir}
    
    [mysqldump]
    ...

Backup-Set files are defined in the "backupsets" directory which is,
by default, ``/etc/holland/backupsets``. The name of the backup-set is 
defined by its configuration filename and can really be most anything. That
means backup-sets can be organized in any arbitrary way, although backup
set files must end in .conf. The file extension is not part of the name of
the backup-set.

As noted above, in order for a backup-set to be active, it must be listed in
the :ref:`backupsets<holland-config-backupsets>` variable.

Backups are placed under the directory defined in the 
:ref:`backup_directory<holland-config-backup_directory>`
section of the main configuration file. Each backup resides under a directory
corresponding to the backup-set name followed by a date-encoded directory.

Provider Plugin Configs
^^^^^^^^^^^^^^^^^^^^^^^

The following are the provider plugins that can be used in a backup-set.
These are used within their own braced section in the backup-set 
configuration file. For specific information on how to configure a
desired provider, see the list below.

For advanced users, the defaults for each provider plugin can be changed
by editing the default configuration file for said provider. These files are 
located in ``/etc/holland/providers`` by default.

.. toctree::
    :maxdepth: 1

    provider_configs/example
    provider_configs/mysqldump
    provider_configs/mysql-lvm
    provider_configs/mysqldump-lvm
    provider_configs/xtrabackup
    provider_configs/pgdump

Backup Set Config Example
^^^^^^^^^^^^^^^^^^^^^^^^^

Here is an example backup set which uses mysqldump to backup all but a
few databases, in a one-file-per-database fashion. For more specific
examples, consult the documentation for the specific provider plugin you
wish to use (see above).

.. code-block:: ini

    [holland:backup]
    plugin = mysqldump
    backups-to-keep = 1
    auto-purge-failures = yes
    purge-policy = after-backup
    estimated-size-factor = 0.25

    [mysqldump]
    extra-defaults = no
    lock-method = auto-detect
    databases = *
    exclude-databases = "mydb", "myotherdb"
    exclude-invalid-views = no
    flush-logs = no
    flush-privileges = yes
    dump-routines = no
    dump-events = no
    stop-slave = no
    max-allowed-packet = 128M
    bin-log-position = no
    file-per-database = yes
    estimate-method = plugin

    [compression]
    method = gzip
    inline = yes
    level = 1

    [mysql:client]
    defaults-extra-file = ~/.my.cnf
