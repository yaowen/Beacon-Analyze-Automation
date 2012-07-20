require './lib/authentication'
module PlusTokenAuthentication
  include Authentication

  PLUS_SIGNUP_S1_TOKEN_KEY = "kVr3WnAhGbjPARghnTAzLOZ62aaWc9Wjv/wy3WxUkeo=".unpack("m").first
  PLUS_SIGNUP_S2_TOKEN_KEY = "VBvpLsQjdvR+FpM9NbMVWJ5/eLaQ7LSsMqQVScNbzxA=".unpack("m").first
  PLUS_USER_TOKEN_KEY = "1dYanh30OXFanypzkVvVHX9Ye6Vul9+iqFKXfktYlEg=".unpack("m").first
  PLUS_EDIT_TOKEN_KEY = "z4yJnZZgtzx8iyr2IgAZEtnfZvsNPUSJf4gwzdoKkRo=".unpack("m").first
  PLUS_ORDER_TOKEN_KEY = "q5W8E6H9x758Hq5wkI0DhSa03MQ5gsoAwf9T910R2k7=".unpack("m").first
  PLUS_PLANID_TOKEN_KEY = "NjAyZjYzNjcxMDYzNTNhMzU3OWQzYTFkMzBiMzM0k7a=".unpack("m").first

  
  def generate_plus_user_token(user_id)
    encrypt_value(PLUS_USER_TOKEN_KEY, user_id)
  end

  def get_user_from_plus_token(token)
    uid = decrypt_value(PLUS_USER_TOKEN_KEY, token)
    uid.to_i
  end

  def generate_plus_edit_token(user_id)
    encrypt_value(PLUS_EDIT_TOKEN_KEY, user_id)
  end

  def validate_plus_edit_token(token, user_id)
    uid = decrypt_value(PLUS_EDIT_TOKEN_KEY, token)
    return (uid.to_i == user_id.to_i && 0 != user_id.to_i)
  end

end
