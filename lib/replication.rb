class Replication
  def initialize(cli:)
    @cli = cli
  end

  def name(db_name)
    "#{db_name}_#{@cli.src_host.gsub('.', '_')}_#{@cli.dest_host.gsub('.', '_')}"
  end

  def src_conn(db_name)
    Sequel.connect("postgres://#{@cli.src_user}:#{@cli.src_password}@#{@cli.src_host}:#{@cli.src_port}/#{db_name}")
  end

  def dest_conn(db_name)
    Sequel.connect("postgres://#{@cli.dest_user}:#{@cli.dest_password}@#{@cli.dest_host}:#{@cli.dest_port}/#{db_name}")
  end

  # AR SRC
  def start_publication(db_name)
    pub_name = name(db_name)
    src_conn = src_conn(db_name)

    pubs = src_conn.fetch("SELECT * FROM pg_publication WHERE pubname='#{pub_name}'")
    if pubs.count > 0
      puts "Publication #{pub_name} in #{db_name} at #{@cli.src_host} already exists"
      return
    end

    sql = "CREATE PUBLICATION #{pub_name} FOR ALL TABLES"
    puts "Create publication #{pub_name} in #{db_name} at #{@cli.src_host}: `#{sql}`"
    src_conn.run(sql)
  end

  # AR SRC
  def stop_publication(db_name)
    pub_name = name(db_name)
    src_conn = src_conn(db_name)

    sql = "DROP PUBLICATION IF EXISTS #{pub_name}"
    puts "Drop publication #{pub_name} in #{db_name} at #{@cli.src_host}"
    src_conn.run(sql)
  end

  # AT DEST
  def start_subscription(db_name)
    sub_name = name(db_name)
    pub_name = name(db_name)
    dest_conn = dest_conn(db_name)

    subs = dest_conn.fetch("SELECT * FROM pg_subscription WHERE subname='#{sub_name}'")
    if subs.count > 0
      puts "Subscription #{sub_name} in #{db_name} at #{@cli.dest_host} already exists"
      return
    end

    sql = "CREATE SUBSCRIPTION #{sub_name} CONNECTION 'user=#{@cli.src_user} #{"password=#{@cli.src_password}" if @cli.src_password.present?} host=#{@cli.src_host} port=#{@cli.src_port} dbname=#{db_name}' PUBLICATION #{pub_name}"
    puts "Create subscription #{sub_name} in #{db_name} at #{@cli.dest_host}: `#{sql}`"
    dest_conn.run(sql)
  end

  # AT DEST
  def stop_subscription(db_name)
    sub_name = name(db_name)
    dest_conn = dest_conn(db_name)

    sql = "DROP SUBSCRIPTION IF EXISTS #{sub_name}"
    puts "Drop subscription #{sub_name} in #{db_name} at #{@cli.dest_host}"
    dest_conn.run(sql)
  end
end
