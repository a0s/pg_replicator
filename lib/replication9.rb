# https://gist.github.com/edib/402d7d29d54a025265c2a5b4d0ee7fe6
# https://blog.dbi-services.com/postgresql-logical-replication-with-pglogical/

class Replication9 < Replication
  def src_dsn(db_name)
    # "host=#{@cli.src_host} port=#{@cli.src_port} user=#{@cli.src_user}#{" password=#{@cli.src_password}" if @cli.src_password.present?} dbname=#{db_name}"
    "host=#{@cli.src_host} port=#{@cli.src_port} user=#{@cli.src_user} dbname=#{db_name}"
  end

  def dest_dsn(db_name)
    "host=#{@cli.dest_host} port=#{@cli.dest_port} user=#{@cli.dest_user} dbname=#{db_name}"
  end

  def src_node_name(pub_name)
    "#{pub_name}_src"
  end

  def dest_node_name(sub_name)
    "#{sub_name}_dest"
  end

  def tables_without_primary_key
    <<-EOS
      select tab.table_schema,
       tab.table_name
      from information_schema.tables tab
      left join information_schema.table_constraints tco 
                on tab.table_schema = tco.table_schema
                and tab.table_name = tco.table_name 
                and tco.constraint_type = 'PRIMARY KEY'
      where tab.table_type = 'BASE TABLE'
            and tab.table_schema not in ('pg_catalog', 'information_schema')
            and tco.constraint_name is null
      order by table_schema,
               table_name;
    EOS
  end

  # AT SRC
  def start_publication(db_name)
    pub_name = name(db_name)
    src_conn = src_conn(db_name)

    src_conn.run("CREATE EXTENSION IF NOT EXISTS pglogical")

    nodes = src_conn.fetch("SELECT node_id FROM pglogical.node WHERE node_name = '#{src_node_name(pub_name)}'")
    if nodes.count == 0
      sql = "SELECT pglogical.create_node(
        node_name := '#{src_node_name(pub_name)}',
        dsn := '#{src_dsn(db_name)}'
      );"
      puts "Create node #{pub_name} in #{db_name} at #{@cli.src_host}: `#{sql}`"
      src_conn.run(sql)
    end

    repl_set = src_conn.fetch("SELECT set_id FROM pglogical.replication_set WHERE set_name = '#{pub_name}'")
    if repl_set.count == 0
      sql = "SELECT pglogical.create_replication_set('#{pub_name}');"
      puts "Create replication set #{pub_name} in #{db_name} at #{@cli.src_host}: `#{sql}`"
      src_conn.run(sql)
    end

    sql  = "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"
    tables = src_conn.fetch(sql).map { |s| s[:table_name] }

    exclude_tables = src_conn.fetch(tables_without_primary_key).map { |s| s[:table_name] }
    puts "!!!! (no primary key) SKIP TABLES: #{exclude_tables.join(',')}"

    (tables - exclude_tables).each do |table|
      sql = "SELECT pglogical.replication_set_add_table('#{pub_name}', '#{table}')"
      puts "Add table '#{table}' into replication set #{pub_name} in #{db_name} at #{@cli.src_host}: `#{sql}`"
      src_conn.run(sql)
    end
  end

  # AT SRC
  def stop_publication(db_name)
    pub_name = name(db_name)
    src_conn = src_conn(db_name)

    sql = "SELECT pglogical.drop_replication_set('#{pub_name}');"
    puts "Drop replication set #{pub_name} in #{db_name} at #{@cli.src_host}: `#{sql}`"
    src_conn.run(sql) rescue nil

    sql = "SELECT pglogical.drop_node('#{pub_name}_src');"
    puts "Drop node set #{pub_name} in #{db_name} at #{@cli.src_host}: `#{sql}`"
    src_conn.run(sql) rescue nil
  end

  # AT DEST
  def start_subscription(db_name)
    sub_name = name(db_name)
    dest_conn = dest_conn(db_name)

    dest_conn.run("CREATE EXTENSION IF NOT EXISTS pglogical")

    nodes = dest_conn.fetch("SELECT node_id FROM pglogical.node WHERE node_name = '#{dest_node_name(sub_name)}'")
    if nodes.count == 0
      sql = "SELECT pglogical.create_node(
        node_name := '#{dest_node_name(sub_name)}',
        dsn := '#{dest_dsn(db_name)}'
      );"
      puts "Create node #{sub_name} in #{db_name} at #{@cli.dest_host}: `#{sql}`"
      dest_conn.run(sql)
    end

    subs = dest_conn.fetch("SELECT * FROM pglogical.subscription WHERE sub_name = '#{sub_name}'")
    if subs.count == 0
      sql = "SELECT pglogical.create_subscription(
      subscription_name := '#{sub_name}',
      replication_sets := array['#{sub_name}'],
      provider_dsn := '#{src_dsn(db_name)}'
    );"
      puts "Create subscription #{sub_name} in #{db_name} at #{@cli.dest_host}: `#{sql}`"
      dest_conn.run(sql)
    end
  end

  # AT DEST
  def stop_subscription(db_name)
    sub_name = name(db_name)
    dest_conn = dest_conn(db_name)

    sql = "SELECT pglogical.drop_subscription('#{sub_name}')"
    puts "Drop subscription #{sub_name} in #{db_name} at #{@cli.dest_host}: `#{sql}`"
    dest_conn.run(sql) rescue nil

    sql = "SELECT pglogical.drop_node('#{sub_name}_dest');"
    puts "Drop node #{sub_name} in #{db_name} at #{@cli.dest_host}: `#{sql}`"
    dest_conn.run(sql) rescue nil
  end
end
