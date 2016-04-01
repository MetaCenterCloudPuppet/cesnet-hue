# == Class hue::hdfs
#
# HDFS initialiations. Actions necessary to launch on HDFS namenode: Create hue user, if needed.
#
# This class is needed to be launched on all HDFS namenodes.
#
class hue::hdfs {
  include ::hue::user
}

