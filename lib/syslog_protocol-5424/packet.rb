module SyslogProtocol5424
  class Packet
    attr_reader :facility, :severity, :hostname, :tag
    attr_accessor :time, :content , :proc_id, :msg_id, :struct_data

    def to_s
      assemble
    end

    def initialize
      @proc_id = @msg_id = @struct_data = "-"
    end
    
    def assemble(max_size = 10240)
      unless @hostname and @facility and @severity and @tag
        raise "Could not assemble packet without hostname, tag, facility, and severity"
      end
      data = "<#{pri}>1 #{generate_timestamp} #{@hostname} #{@tag} #{@proc_id} #{@msg_id} #{@struct_data} #{@content}"

      if string_bytesize(data) > max_size
        data = data.slice(0, max_size)
        while string_bytesize(data) > max_size
          data = data.slice(0, data.length - 1)
        end
      end

      data
    end

    def facility=(f)
      if f.is_a? Integer
        if (0..23).include?(f)
          @facility = f
        else
          raise ArgumentError.new "Facility must be within 0-23"
        end
      elsif f.is_a? String
        if facility = FACILITIES[f]
          @facility = facility
        else
          raise ArgumentError.new "'#{f}' is not a designated facility"
        end
      else
        raise ArgumentError.new "Facility must be a designated number or string"
      end
    end

    def tag=(t)
      unless t && t.is_a?(String) && t.length > 0
        raise ArgumentError, "Tag must not be omitted"
      end
      if t =~ /\s/
        raise ArgumentError, "Tag may not contain spaces"
      end
      if t =~ /[^\x21-\x7E]/
        raise ArgumentError, "Tag may only contain ASCII characters 33-126"
      end
      if t.length > 48   # don't raise error, instead shrink tag to 48 characters
        t = t[0,48]
      end

      @tag = t
    end

    def severity=(s)
      if s.is_a? Integer
        if (0..7).include?(s)
          @severity = s
        else
          raise ArgumentError.new "Severity must be within 0-7"
        end
      elsif s.is_a? String
        if severity = SEVERITIES[s]
          @severity = severity
        else
          raise ArgumentError.new "'#{s}' is not a designated severity"
        end
      else
        raise ArgumentError.new "Severity must be a designated number or string"
      end
    end

    def hostname=(h)
      unless h and h.is_a? String and h.length > 0
        raise ArgumentError.new("Hostname may not be omitted")
      end
      if h =~ /\s/
        raise ArgumentError.new("Hostname may not contain spaces")
      end
      if h =~ /[^\x21-\x7E]/
        raise ArgumentError.new("Hostname may only contain ASCII characters 33-126")
      end
      @hostname = h
    end

    def facility_name
      FACILITY_INDEX[@facility]
    end

    def severity_name
      SEVERITY_INDEX[@severity]
    end

    def pri
      (@facility * 8) + @severity
    end

    def pri=(p)
      unless p.is_a? Integer and (0..191).include?(p)
        raise ArgumentError.new "PRI must be a number between 0 and 191"
      end
      @facility = p / 8
      @severity = p - (@facility * 8)
    end

    def generate_timestamp
      time = @time || Time.now
      time.strftime("%FT%T.%6N%:z")
      # time.strftime("%FT%T%6NZ") # UTC time
    end

    if "".respond_to?(:bytesize)
      def string_bytesize(string)
        string.bytesize
      end
    else
      def string_bytesize(string)
        string.length
      end
    end

    SEVERITIES.each do |k,v|
      define_method("#{k}?") { SEVERITIES[k] == @severity }
    end
  end
end