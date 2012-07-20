# Helper methods for authentication.  Provides cookie handling for the
# user in instance variable @user.
require 'openssl'
module Authentication

  # Encrypt a single 32-bit integer with the given key under AES-256-ECB.  Key
  # should be 32-bytes long (256-bits).
  def encrypt_value key, value
    s =  [value.to_i, Time.now.utc.to_i & 0xffffffff].pack('II')
    s << OpenSSL::Random.random_bytes(7)

    cipher = OpenSSL::Cipher::Cipher.new('aes-256-ecb')
    cipher.encrypt
    cipher.key = key
    s = cipher.update(s) << cipher.final

    base64_encode(s)
  end

  # Decrypt a single 32-bit integer with the given key under AES-256-ECB.  Key
  # should be 32-bytes long (256-bits).  Expiration should be given in seconds.
  def decrypt_value key, data

    id, ts = decrypt_value_ts(key, data)
    return nil if id.nil? || ts.nil?

    # bail if we're expired

    return nil unless id > 0

    id
  end

  # Decrypt a single 32-bit integer with the given key under AES-256-ECB.  Key
  # should be 32-bytes long (256-bits).  Returns id and time stamp.
  def decrypt_value_ts key, data
    return nil unless data
    s = base64_decode(data)

    return nil unless !s.empty? && s.length == 16
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-ecb')
    cipher.decrypt
    cipher.key = key
    s = cipher.update(s) << cipher.final

    return nil unless s
    id, ts = s.unpack("II")

  rescue
    # catch bad data errors
    raise unless $!.message =~ /bad decrypt/
    [nil, nil]
  end

  # uid + 4 random digits, base64 encoded
  def encode_uid uid
    s = "%s%04d" % [uid.to_s, (rand() * 10000 % 10000)]
    base64_encode(s)
  end

  def base64_encode s
    [s].pack("m").tr('+', '-').tr('/', '_').sub(/=*\s*$/, '')
  end

  def base64_decode s
    s = s.dup
    n = 4 - s.length % 4
    s << "=" * n if n < 4
    s.tr('-', '+').tr('_', '/').unpack("m").first
  end

end
