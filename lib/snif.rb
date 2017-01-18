require 'packetfu'
require 'pry'
require 'bindata'

iface = ARGV[0] || PacketFu::Utils.default_int

cap = PacketFu::Capture.new(:iface => iface, :start => true, :filter => "ip")


def is_kafka_tcp? (p)
  (p.peek[0] == "T") and ([9092,9093,9094].member?(p.tcp_dport)) and (p.payload.size > 0)
end

PROTOCOL_MAPPING = { produce_request: 0,
                     fetch_request: 1,
                     offset_request: 2,
                     metadata_request: 3,
                     offset_commit_request: 8,
                     offset_fetch_request: 9,
                     group_coordinator_request: 10,
                     join_group_request: 11,
                     heartbeat_request: 12,
                     leave_group_request: 13,
                     sync_group_request: 14,
                     describe_groups_request: 15,
                     list_groups_request: 16 }.invert

class KafkaRequest < BinData::Record
  endian :big

  int32 :payload_length

  int16 :api_key
  int16 :api_version
  int32 :correlation_id
  int16 :client_length
  string :client_id, length: :client_length
end

class KafkaProduceRequest < KafkaRequest
  int16 :acks
  int32 :timeout
  int32 :partitions
  int16 :topic_length
  string :topic, length: :topic_length
  int32 :message_set_size
end

class KafkaMetadataRequest < KafkaRequest
  int32 :topics_set_size
  array :topics, initial_length: :topics_set_size do
    int16 :topic_length
    string :topic_name, length: :topic_length
  end
end

class KafkaFetchRequest < KafkaRequest
  int32 :replica_id
  int32 :max_wait_time
  int32 :min_bytes

  int32 :topics_set_size
  int16 :topic_length
  string :topic_name, length: :topic_length
  int32 :partitions_set_size
  int32 :partitions
  int64 :fetch_offset
  int32 :max_bytes
end

class PacketFu::TCPPacket
  def api_type
    _, api_key = self.payload.unpack("Nn")
    PROTOCOL_MAPPING[api_key]
  end

  def to_iptables
    request_header = KafkaRequest.read(self.payload)
    before_correlation_id = request_header.to_hex.byteslice(request_header.offset_of(request_header.api_key)*2,
                                                            request_header.offset_of(request_header.api_version)*2)
    after_correlation_id = request_header.to_hex.byteslice(request_header.offset_of(request_header.client_length)*2,
                                                           request_header.num_bytes*2)

    "iptables -I DOCKER 1 %s %s -p tcp --dport %d -j REJECT --reject-with tcp-reset" % [build_match_string(before_correlation_id),
                                                                                        build_match_string(after_correlation_id),
                                                                                        self.tcp_dport]
  end

  private

  def build_match_string(hex_str)
    %Q{ -m string --hex-string "|#{hex_str}|" --algo bm }
  end
end

def destination_topic?(p)
  p.api_type == :produce_request and
    KafkaProduceRequest.read(p.payload).topic == "young-pets"
end

loop do
  cap.stream.each do |pkt|
    packet = PacketFu::Packet.parse(pkt)
    if is_kafka_tcp?(packet)
      binding.pry if destination_topic?(packet)
      puts "#{Time.now}  #{packet.api_type} \n #{packet.payload.dump} \n"
    end
  end
end
