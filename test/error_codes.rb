module ErrorCodes
	# Generic request errors
	UNEXPECTED_ERROR = 1000
	AUTHENTICATION_FAILED = 1001
	ACTION_NOT_ALLOWED = 1002
	CONTENT_TYPE_NOT_SUPPORTED = 1003

	# Errors for missing headers
	AUTH_HEADER_MISSING = 1100
	CONTENT_TYPE_HEADER_MISSING = 1101

	# File errors
	CONTENT_TYPE_DOES_NOT_MATCH_FILE_TYPE = 1200
	IMAGE_FILE_INVALID = 1201
	IMAGE_FILE_TOO_LARGE = 1202

	# Generic request body errors
	INVALID_BODY = 2000
	PURCHASE_REQUIRES_AT_LEAST_ONE_TABLE_OBJECT = 2001

	# Missing fields
	ACCESS_TOKEN_MISSING = 2100
	APP_ID_MISSING = 2101
	TABLE_ID_MISSING = 2102
	EMAIL_MISSING = 2103
	FIRST_NAME_MISSING = 2104
	PASSWORD_MISSING = 2105
	EMAIL_CONFIRMATION_TOKEN_MISSING = 2106
	PASSWORD_CONFIRMATION_TOKEN_MISSING = 2107
	COUNTRY_MISSING = 2108
	API_KEY_MISSING = 2109
	NAME_MISSING = 2110
	DESCRIPTION_MISSING = 2111
	PROPERTIES_MISSING = 2112
	PRODUCT_NAME_MISSING = 2115
	PRODUCT_IMAGE_MISSING = 2116
	CURRENCY_MISSING = 2117
	ENDPOINT_MISSING = 2118
	P256DH_MISSING = 2119
	AUTH_MISSING = 2120
	TIME_MISSING = 2121
	INTERVAL_MISSING = 2122
	TITLE_MISSING = 2123
	BODY_MISSING = 2124
	PATH_MISSING = 2125
	METHOD_MISSING = 2126
	COMMANDS_MISSING = 2127
	ERRORS_MISSING = 2128
	ENV_VARS_MISSING = 2129
	TABLE_OBJECTS_MISSING = 2130
	PLAN_MISSING = 2132
	SUCCESS_URL_MISSING = 2133
	CANCEL_URL_MISSING = 2134

	# Fields with wrong type
	ACCESS_TOKEN_WRONG_TYPE = 2200
	UUID_WRONG_TYPE = 2201
	APP_ID_WRONG_TYPE = 2202
	TABLE_ID_WRONG_TYPE = 2203
	EMAIL_WRONG_TYPE = 2204
	FIRST_NAME_WRONG_TYPE = 2205
	PASSWORD_WRONG_TYPE = 2206
	EMAIL_CONFIRMATION_TOKEN_WRONG_TYPE = 2207
	PASSWORD_CONFIRMATION_TOKEN_WRONG_TYPE = 2208
	COUNTRY_WRONG_TYPE = 2209
	API_KEY_WRONG_TYPE = 2210
	DEVICE_NAME_WRONG_TYPE = 2211
	DEVICE_OS_WRONG_TYPE = 2213
	NAME_WRONG_TYPE = 2214
	DESCRIPTION_WRONG_TYPE = 2215
	PUBLISHED_WRONG_TYPE = 2216
	WEB_LINK_WRONG_TYPE = 2217
	GOOGLE_PLAY_LINK_WRONG_TYPE = 2218
	MICROSOFT_STORE_LINK_WRONG_TYPE = 2219
	FILE_WRONG_TYPE = 2220
	PROPERTIES_WRONG_TYPE = 2221
	PROPERTY_NAME_WRONG_TYPE = 2222
	PROPERTY_VALUE_WRONG_TYPE = 2223
	EXT_WRONG_TYPE = 2224
	PRODUCT_NAME_WRONG_TYPE = 2227
	PRODUCT_IMAGE_WRONG_TYPE = 2228
	CURRENCY_WRONG_TYPE = 2229
	ENDPOINT_WRONG_TYPE = 2230
	P256DH_WRONG_TYPE = 2231
	AUTH_WRONG_TYPE = 2232
	TIME_WRONG_TYPE = 2233
	INTERVAL_WRONG_TYPE = 2234
	TITLE_WRONG_TYPE = 2235
	BODY_WRONG_TYPE = 2236
	PATH_WRONG_TYPE = 2237
	METHOD_WRONG_TYPE = 2238
	COMMANDS_WRONG_TYPE = 2239
	CACHING_WRONG_TYPE = 2240
	PARAMS_WRONG_TYPE = 2241
	ERRORS_WRONG_TYPE = 2242
	CODE_WRONG_TYPE = 2243
	MESSAGE_WRONG_TYPE = 2244
	ENV_VARS_WRONG_TYPE = 2245
	ENV_VAR_NAME_WRONG_TYPE = 2246
	ENV_VAR_VALUE_WRONG_TYPE = 2247
	TABLE_OBJECTS_WRONG_TYPE = 2248
	PLAN_WRONG_TYPE = 2250
	SUCCESS_URL_WRONG_TYPE = 2251
	CANCEL_URL_WRONG_TYPE = 2252
	MODE_WRONG_TYPE = 2253

	# Too short fields
	FIRST_NAME_TOO_SHORT = 2300
	PASSWORD_TOO_SHORT = 2301
	DEVICE_NAME_TOO_SHORT = 2302
	DEVICE_OS_TOO_SHORT = 2304
	NAME_TOO_SHORT = 2305
	DESCRIPTION_TOO_SHORT = 2306
	WEB_LINK_TOO_SHORT = 2307
	GOOGLE_PLAY_LINK_TOO_SHORT = 2308
	MICROSOFT_STORE_LINK_TOO_SHORT = 2309
	PROPERTY_NAME_TOO_SHORT = 2310
	PROPERTY_VALUE_TOO_SHORT = 2311
	EXT_TOO_SHORT = 2312
	PRODUCT_NAME_TOO_SHORT = 2315
	PRODUCT_IMAGE_TOO_SHORT = 2316
	ENDPOINT_TOO_SHORT = 2317
	P256DH_TOO_SHORT = 2318
	AUTH_TOO_SHORT = 2319
	TITLE_TOO_SHORT = 2320
	BODY_TOO_SHORT = 2321
	PATH_TOO_SHORT = 2322
	COMMANDS_TOO_SHORT = 2323
	PARAMS_TOO_SHORT = 2324
	MESSAGE_TOO_SHORT = 2325
	ENV_VAR_NAME_TOO_SHORT = 2326
	ENV_VAR_VALUE_TOO_SHORT = 2327
	SLOT_TOO_SHORT = 2328

	# Too long fields
	FIRST_NAME_TOO_LONG = 2400
	PASSWORD_TOO_LONG = 2401
	DEVICE_NAME_TOO_LONG = 2402
	DEVICE_OS_TOO_LONG = 2404
	NAME_TOO_LONG = 2405
	DESCRIPTION_TOO_LONG = 2406
	WEB_LINK_TOO_LONG = 2407
	GOOGLE_PLAY_LINK_TOO_LONG = 2408
	MICROSOFT_STORE_LINK_TOO_LONG = 2409
	PROPERTY_NAME_TOO_LONG = 2410
	PROPERTY_VALUE_TOO_LONG = 2411
	EXT_TOO_LONG = 2412
	PRODUCT_NAME_TOO_LONG = 2415
	PRODUCT_IMAGE_TOO_LONG = 2416
	ENDPOINT_TOO_LONG = 2417
	P256DH_TOO_LONG = 2418
	AUTH_TOO_LONG = 2419
	TITLE_TOO_LONG = 2420
	BODY_TOO_LONG = 2421
	PATH_TOO_LONG = 2422
	COMMANDS_TOO_LONG = 2423
	PARAMS_TOO_LONG = 2424
	MESSAGE_TOO_LONG = 2425
	ENV_VAR_NAME_TOO_LONG = 2426
	ENV_VAR_VALUE_TOO_LONG = 2427
	SLOT_TOO_LONG = 2428

	# Invalid fields
	EMAIL_INVALID = 2500
	NAME_INVALID = 2501
	WEB_LINK_INVALID = 2502
	GOOGLE_PLAY_LINK_INVALID = 2503
	MICROSOFT_STORE_LINK_INVALID = 2504
	METHOD_INVALID = 2505
	PLAN_INVALID = 2507
	SUCCESS_URL_INVALID = 2508
	CANCEL_URL_INVALID = 2509
	MODE_INVALID = 2510
	PRODUCT_IMAGE_INVALID = 2511

	# Generic state errors
	USER_IS_ALREADY_CONFIRMED = 3000
	USER_OF_TABLE_OBJECT_MUST_HAVE_PROVIDER = 3001
	USER_ALREADY_PURCHASED_THIS_TABLE_OBJECT = 3002
	USER_HAS_NO_PAYMENT_INFORMATION = 3003
	USER_ALREADY_HAS_STRIPE_CUSTOMER = 3004
	TABLE_OBJECT_IS_NOT_FILE = 3005
	TABLE_OBJECT_HAS_NO_FILE = 3006
	NOT_SUFFICIENT_STORAGE_AVAILABLE = 3007
	TABLE_OBJECTS_NEED_TO_BELONG_TO_THE_SAME_USER = 3009
	PURCHASE_CANNOT_BE_DELETED = 3010
	USER_IS_ALREADY_ON_PLAN = 3011

	# Access token errors
	CANNOT_USE_OLD_ACCESS_TOKEN = 3100
	ACCESS_TOKEN_MUST_BE_RENEWED = 3101

	# Incorrect values
	INCORRECT_PASSWORD = 3200
	INCORRECT_EMAIL_CONFIRMATION_TOKEN = 3201
	INCORRECT_PASSWORD_CONFIRMATION_TOKEN = 3202

	# Not supported values
	COUNTRY_NOT_SUPPORTED = 3300

	# Errors for values already in use
	UUID_ALREADY_IN_USE = 3400
	EMAIL_ALREADY_IN_USE = 3401

	# Errors for empty values in User
	OLD_EMAIL_OF_USER_IS_EMPTY = 3500
	NEW_EMAIL_OF_USER_IS_EMPTY = 3501
	NEW_PASSWORD_OF_USER_IS_EMPTY = 3502

	# Errors for not existing resources
	USER_DOES_NOT_EXIST = 3600
	DEV_DOES_NOT_EXIST = 3601
	PROVIDER_DOES_NOT_EXIST = 3602
	SESSION_DOES_NOT_EXIST = 3603
	APP_DOES_NOT_EXIST = 3604
	TABLE_DOES_NOT_EXIST = 3605
	TABLE_OBJECT_DOES_NOT_EXIST = 3606
	TABLE_OBJECT_PRICE_DOES_NOT_EXIST = 3607
	TABLE_OBJECT_USER_ACCESS_DOES_NOT_EXIST = 3608
	PURCHASE_DOES_NOT_EXIST = 3609
	WEB_PUSH_SUBSCRIPTION_DOES_NOT_EXIST = 3610
	NOTIFICATION_DOES_NOT_EXIST = 3611
	API_DOES_NOT_EXIST = 3612
	API_ENDPOINT_DOES_NOT_EXIST = 3613
	API_SLOT_DOES_NOT_EXIST = 3615
	COLLECTION_DOES_NOT_EXIST = 3616

	# Errors for already existing resources
	PROVIDER_ALREADY_EXISTS = 3702
	TABLE_OBJECT_USER_ACCESS_ALREADY_EXISTS = 3708
end