require 'fdb'

# An OpenFlow controller that emulates a layer-2 switch.
class LearningSwitch13 < Trema::Controller
  timer_event :age_fdb, interval: 5.sec

  INGRESS_FILTERING_TABLE_ID = 0
  FORWARDING_TABLE_ID = 1

  AGING_TIME = 180

  def start(_args)
    @fdb = FDB.new
    logger.info "#{name} started."
  end

  def switch_ready(datapath_id)
    add_multicast_mac_drop_flow_entry(datapath_id)
    add_ipv6_multicast_mac_drop_flow_entry(datapath_id)
    add_default_broadcast_flow_entry(datapath_id)
    add_default_flooding_flow_entry(datapath_id)
    add_default_forwarding_flow_entry(datapath_id)
  end

  def packet_in(_datapath_id, message)
    @fdb.learn(message.source_mac, message.in_port)
    add_forwarding_flow_and_packet_out(message)
  end

  def age_fdb
    @fdb.age
  end

  private

  def add_forwarding_flow_and_packet_out(message)
    port_no = @fdb.lookup(message.destination_mac)
    add_forwarding_flow_entry(message, port_no) if port_no
    packet_out(message, port_no || :flood)
  end

  def add_forwarding_flow_entry(message, port_no)
    send_flow_mod_add(
      message.datapath_id,
      table_id: FORWARDING_TABLE_ID,
      idle_timeout: AGING_TIME,
      priority: 2,
      match: Match.new(in_port: message.in_port,
                       destination_mac_address: message.destination_mac,
                       source_mac_address: message.source_mac),
      instructions: Apply.new(SendOutPort.new(port_no))
    )
  end

  def packet_out(message, port_no)
    send_packet_out(
      message.datapath_id,
      packet_in: message,
      actions: SendOutPort.new(port_no)
    )
  end

  def add_default_broadcast_flow_entry(datapath_id)
    send_flow_mod_add(
      datapath_id,
      table_id: FORWARDING_TABLE_ID,
      idle_timeout: 0,
      priority: 3,
      match: Match.new(destination_mac_address: 'ff:ff:ff:ff:ff:ff'),
      instructions: Apply.new(SendOutPort.new(:flood))
    )
  end

  def add_default_flooding_flow_entry(datapath_id)
    send_flow_mod_add(
      datapath_id,
      table_id: FORWARDING_TABLE_ID,
      idle_timeout: 0,
      priority: 1,
      match: Match.new,
      instructions: Apply.new(SendOutPort.new(:controller))
    )
  end

  def add_multicast_mac_drop_flow_entry(datapath_id)
    send_flow_mod_add(
      datapath_id,
      table_id: INGRESS_FILTERING_TABLE_ID,
      idle_timeout: 0,
      priority: 2,
      match: Match.new(destination_mac_address: '01:00:00:00:00:00',
                       destination_mac_address_mask: 'ff:00:00:00:00:00')
    )
  end

  def add_ipv6_multicast_mac_drop_flow_entry(datapath_id)
    send_flow_mod_add(
      datapath_id,
      table_id: INGRESS_FILTERING_TABLE_ID,
      idle_timeout: 0,
      priority: 2,
      match: Match.new(destination_mac_address: '33:33:00:00:00:00',
                       destination_mac_address_mask: 'ff:ff:00:00:00:00')
    )
  end

  def add_default_forwarding_flow_entry(datapath_id)
    send_flow_mod_add(
      datapath_id,
      table_id: INGRESS_FILTERING_TABLE_ID,
      idle_timeout: 0,
      priority: 1,
      match: Match.new,
      instructions: GotoTable.new(FORWARDING_TABLE_ID)
    )
  end
end
