module ErrorCodes
	UNEXPECTED_ERROR = 1101
	AUTHENTICATION_FAILED = 1102
	ACTION_NOT_ALLOWED = 1103
	CONTENT_TYPE_NOT_SUPPORTED = 1104
	INVALID_BODY = 1105
	TABLE_OBJECT_IS_NOT_FILE = 1106
	TABLE_OBJECT_HAS_NO_FILE = 1107
	NO_SUFFICIENT_STORAGE_AVAILABLE = 1108

	WRONG_PASSWORD = 1201

	JWT_INVALID = 1301

	AUTH_HEADER_MISSING = 2101
	JWT_MISSING = 2102
	EMAIL_MISSING = 2103
	FIRST_NAME_MISSING = 2104
	PASSWORD_MISSING = 2105
	APP_ID_MISSING = 2106
	API_KEY_MISSING = 2107
	NAME_MISSING = 2108
	TABLE_ID_MISSING = 2109
	PROPERTIES_MISSING = 2110
	ENDPOINT_MISSING = 2111
	P256DH_MISSING = 2112
	AUTH_MISSING = 2113
	TIME_MISSING = 2114
	INTERVAL_MISSING = 2115
	TITLE_MISSING = 2116
	BODY_MISSING = 2117

	EMAIL_WRONG_TYPE = 2201
	FIRST_NAME_WRONG_TYPE = 2202
	PASSWORD_WRONG_TYPE = 2203
	APP_ID_WRONG_TYPE = 2204
	API_KEY_WRONG_TYPE = 2205
	DEVICE_NAME_WRONG_TYPE = 2206
	DEVICE_TYPE_WRONG_TYPE = 2207
	DEVICE_OS_WRONG_TYPE = 2208
	NAME_WRONG_TYPE = 2209
	UUID_WRONG_TYPE = 2210
	TABLE_ID_WRONG_TYPE = 2211
	FILE_WRONG_TYPE = 2212
	PROPERTIES_WRONG_TYPE = 2213
	PROPERTY_NAME_WRONG_TYPE = 2214
	PROPERTY_VALUE_WRONG_TYPE = 2215
	EXT_WRONG_TYPE = 2216
	TABLE_ALIAS_WRONG_TYPE = 2217
	ENDPOINT_WRONG_TYPE = 2218
	P256DH_WRONG_TYPE = 2219
	AUTH_WRONG_TYPE = 2220
	TIME_WRONG_TYPE = 2221
	INTERVAL_WRONG_TYPE = 2222
	TITLE_WRONG_TYPE = 2223
	BODY_WRONG_TYPE = 2224

	FIRST_NAME_TOO_SHORT = 2301
	PASSWORD_TOO_SHORT = 2302
	DEVICE_NAME_TOO_SHORT = 2303
	DEVICE_TYPE_TOO_SHORT = 2304
	DEVICE_OS_TOO_SHORT = 2305
	NAME_TOO_SHORT = 2306
	PROPERTY_NAME_TOO_SHORT = 2307
	PROPERTY_VALUE_TOO_SHORT = 2308
	EXT_TOO_SHORT = 2309
	ENDPOINT_TOO_SHORT = 2310
	P256DH_TOO_SHORT = 2311
	AUTH_TOO_SHORT = 2312
	TITLE_TOO_SHORT = 2313
	BODY_TOO_SHORT=  2314

	FIRST_NAME_TOO_LONG = 2401
	PASSWORD_TOO_LONG = 2402
	DEVICE_NAME_TOO_LONG = 2403
	DEVICE_TYPE_TOO_LONG = 2404
	DEVICE_OS_TOO_LONG = 2405
	NAME_TOO_LONG = 2406
	PROPERTY_NAME_TOO_LONG = 2407
	PROPERTY_VALUE_TOO_LONG = 2408
	EXT_TOO_LONG = 2409
	ENDPOINT_TOO_LONG = 2410
	P256DH_TOO_LONG = 2411
	AUTH_TOO_LONG = 2412
	TITLE_TOO_LONG = 2413
	BODY_TOO_LONG = 2414

	EMAIL_INVALID = 2501
	NAME_INVALID = 2502
	
	EMAIL_ALREADY_TAKEN = 2701
	UUID_ALREADY_TAKEN = 2702

	USER_DOES_NOT_EXIST = 2801
	DEV_DOES_NOT_EXIST = 2802
	APP_DOES_NOT_EXIST = 2803
	TABLE_DOES_NOT_EXIST = 2804
	TABLE_OBJECT_DOES_NOT_EXIST = 2805
	SESSION_DOES_NOT_EXIST = 2806
	TABLE_OBJECT_USER_ACCESS_DOES_NOT_EXIST = 2807
	NOTIFICATION_DOES_NOT_EXIST = 2808

	TABLE_OBJECT_USER_ACCESS_ALREADY_EXISTS = 2901
end