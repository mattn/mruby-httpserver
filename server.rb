# require-mrbgems
#   Asmod4n/mruby-phr
#   mattn/mruby-onig-regexp
#   iij/mruby-env
#   mruby-io
#   mruby-socket

@cache = {}
@ctmap = {
 'txt'  => 'text/plain',
 'html' => 'text/html',
 'css'  => 'text/css',
 'jpg'  => 'image/jpeg',
 'png'  => 'image/png',
 'gif'  => 'image/gif',
}
@filedir = 'static'
@logger = Logger.new STDERR

def read_file(name)
  File.open(name, 'rb') do |f|
    f.read(File.size(name))
  end
end

def handle_request(s)
  payload = s.gets rescue nil
  return false unless payload
  is_post = payload.start_with?('POST ')

  post = ''
  if is_post || payload =~ / HTTP\/1\.[01]\r?\n/
    n = nil
    while true
      payload += s.gets
      n = payload.index /\r?\n\r?\n/
      break unless n.nil?
    end
    unless n.nil?
      payload, post = payload[0..n+3], payload[n+4..-1]
    end
  end
  phr = Phr.new
  offset = phr.parse_request payload
  raise offset.to_s if offset.is_a? Symbol
  @logger.info "#{phr.method} #{phr.path}"
  if is_post
    n = phr.headers.index {|x| x[0] == 'content-length'}
    l = n.nil? ? 0 : phr.headers[n][1].to_i
    post += l > 0 ? s.read(l) : s.read
  end
  path = phr.path.gsub('\+',' ').gsub(/%([A-Fa-f0-9][A-Fa-f0-9])/) { [$1.hex].pack('C') }
  path = path + (phr.path[-1] == '/' ? 'index.html' : '')
  path.gsub!('\\', '_')
  ct = @ctmap[path.split(".")[-1]] || 'application/octet-stream'

  item = @cache[path]
  now = Time.now.to_i
  if item && item[:epoch] >= now - 5
    body = item[:body]
    @cache[path][:epoch] = now
  else
    begin
      body = read_file(@filedir + path)
    rescue
      s.write "HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\nNot Found"
      s.close
      return false
    end
    @cache[path] = {:body => body, :epoch => now}
  end
  n = phr.headers.index {|x| x[0] == 'connection'}
  keepalive = true || n.nil? || phr.headers[n][1].downcase != 'keep-alive'
  phr.reset
  # TODO handle multiple requset
  if keepalive
    s.write "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: #{ct}\r\nContent-Length: #{body.size}\r\n\r\n#{body}"
    s.close
    return false
  end
  s.write "HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nContent-Type: #{ct}\r\nContent-Length: #{body.size}\r\n\r\n#{body}"
  true
end

port = 
server = TCPServer.open(host = '0.0.0.0', service = (ENV['PORT'] || '8001').to_i)
n = 0
while true
  s = server.accept
  begin
    handle_request(s)
  rescue => e
    p e
  ensure
    s.close rescue 0 unless s.closed?
  end
  GC.start
end

server.close

# vim:set et sw=2 ts=2:
