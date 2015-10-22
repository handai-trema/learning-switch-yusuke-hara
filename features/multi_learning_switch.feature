Feature: "Multi Learning Switch" example
  Background:
    Given a file named "trema.conf" with:
    """
    vswitch('lsw1') { datapath_id 0x1 }
    vswitch('lsw2') { datapath_id 0x2 }

    vhost('host1-1')
    vhost('host1-2')
    vhost('host2-1')
    vhost('host2-2')

    link 'lsw1', 'host1-1'
    link 'lsw1', 'host1-2'
    link 'lsw2', 'host2-1'
    link 'lsw2', 'host2-2'
    """

  @sudo
  Scenario: Run
    Given I trema run "lib/multi_learning_switch.rb" interactively with the configuration "trema.conf"
    And I run `sleep 10`
    When I run `trema send_packets --source host1-1 --dest host1-2 --npackets 2`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       0 |
    When I run `trema send_packets --source host2-1 --dest host2-2 --npackets 3`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |
    When I run `trema send_packets --source host2-2 --dest host1-1 --npackets 2`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |
    When I run `trema send_packets --source host1-2 --dest host2-1 --npackets 4`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |
    When I run `trema send_packets --source host1-1 --dest host2-2 --npackets 1`
    And the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |

  @sudo
  Scenario: Run as a daemon
    Given I trema run "lib/multi_learning_switch.rb" with the configuration "trema.conf"
    And I run `sleep 10`
    When I successfully run `trema send_packets --source host1-1 --dest host1-2 --npackets 2`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       0 |
    When I successfully run `trema send_packets --source host2-1 --dest host2-2 --npackets 3`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |
    When I successfully run `trema send_packets --source host2-2 --dest host1-1 --npackets 2`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |
    When I successfully run `trema send_packets --source host1-2 --dest host2-1 --npackets 4`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |
    When I successfully run `trema send_packets --source host1-1 --dest host2-2 --npackets 1`
    Then the total number of received packets should be:
      | host1-1 | host1-2 | host2-1 | host2-2 |
      |       0 |       2 |       0 |       3 |
