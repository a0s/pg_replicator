class Cli
  attr_reader :opts, :src_url, :src_databases, :dest_control_url

  def parse
    @opts = Slop.parse do |o|
      o.string '--src-databases', 'src database name(s) comma separated', required: true

      o.string '--src-host', 'src host', default: 'localhost'
      o.integer '--src-port', 'src port', default: 5432
      o.string '--src-user', 'src user', default: 'postgres'
      o.string '--src-password', 'src password', default: ''

      o.string '--dest-host', 'dest host', default: 'localhost'
      o.integer '--dest-port', 'dest port', default: 5432
      o.string '--dest-user', 'dest user', default: 'postgres'
      o.string '--dest-password', 'dest password', default: ''

      o.bool '--help' do
        puts "Drop and recreate (scheme only) database on dest by schemes from src"
        puts o
        exit
      end
    end

    @src_url = "postgres://#{src_user}:#{src_password}@#{src_host}:#{src_port}"
    @src_databases = @opts[:"src-databases"].split(',')
    @dest_control_url = "postgres://#{@opts[:"dest-user"]}:#{@opts[:"dest-password"]}@#{@opts[:"dest-host"]}:#{@opts[:"dest-port"]}/postgres"

    self
  end

  def src_user
    @opts[:"src-user"]
  end

  def src_password
    @opts[:"src-password"]
  end

  def src_host
    @opts[:"src-host"]
  end

  def src_port
    @opts[:"src-port"]
  end


  def dest_user
    @opts[:"dest-user"]
  end

  def dest_password
    @opts[:"dest-password"]
  end

  def dest_host
    @opts[:"dest-host"]
  end

  def dest_port
    @opts[:"dest-port"]
  end
end
