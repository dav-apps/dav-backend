module Constants
	JWT_EXPIRATION_HOURS_PROD = 7000
	JWT_EXPIRATION_HOURS_DEV = 10000000

	DEFAULT_TABLE_COUNT = 100
	DEFAULT_TABLE_PAGE = 1

	SIZE_PROPERTY_NAME = "size"
	TYPE_PROPERTY_NAME = "type"
	ETAG_PROPERTY_NAME = "etag"
	EXT_PROPERTY_NAME = "ext"

	# Constants for field lengths
	FIRST_NAME_MIN_LENGTH = 2
	FIRST_NAME_MAX_LENGTH = 20
	PASSWORD_MIN_LENGTH = 7
	PASSWORD_MAX_LENGTH = 25
	DEVICE_NAME_MIN_LENGTH = 2
	DEVICE_NAME_MAX_LENGTH = 30
	DEVICE_TYPE_MIN_LENGTH = 2
	DEVICE_TYPE_MAX_LENGTH = 30
	DEVICE_OS_MIN_LENGTH = 2
	DEVICE_OS_MAX_LENGTH = 30
	NAME_MIN_LENGTH = 2
	NAME_MAX_LENGTH = 20
	PROPERTY_NAME_MIN_LENGTH = 1
	PROPERTY_NAME_MAX_LENGTH = 100
	PROPERTY_VALUE_MIN_LENGTH = 1
	PROPERTY_VALUE_MAX_LENGTH = 65000
	EXT_MIN_LENGTH = 1
	EXT_MAX_LENGTH = 5
	ENDPOINT_MIN_LENGTH = 1
	ENDPOINT_MAX_LENGTH = 250
	P256DH_MIN_LENGTH = 1
	P256DH_MAX_LENGTH = 250
	AUTH_MIN_LENGTH = 1
	AUTH_MAX_LENGTH = 250
	TITLE_MIN_LENGTH = 2
	TITLE_MAX_LENGTH = 40
	BODY_MIN_LENGTH = 2
	BODY_MAX_LENGTH = 150
	PATH_MIN_LENGTH = 2
	PATH_MAX_LENGTH = 150
	COMMANDS_MIN_LENGTH = 2
	COMMANDS_MAX_LENGTH = 65000
	PARAMS_MIN_LENGTH = 0
	PARAMS_MAX_LENGTH = 200
	MESSAGE_MIN_LENGTH = 2
	MESSAGE_MAX_LENGTH = 200
	VALUE_MIN_LENGTH = 2
	VALUE_MAX_LENGTH = 250

	# Constants for tests
	MATT_PASSWORD = "schachmatt"
end