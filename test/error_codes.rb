module ErrorCodes
	UNEXPECTED_ERROR = 1101
	AUTHENTICATION_FAILED = 1102
	ACTION_NOT_ALLOWED = 1103
	CONTENT_TYPE_NOT_SUPPORTED = 1104
	INVALID_BODY = 1105
	TABLE_OBJECT_IS_NOT_FILE = 1106
	TABLE_OBJECT_HAS_NO_FILE = 1107
	NO_SUFFICIENT_STORAGE_AVAILABLE = 1108
	USER_IS_ALREADY_CONFIRMED = 1109
	IMAGE_FILE_INVALID = 1110
	IMAGE_FILE_TOO_LARGE = 1111
	CONTENT_TYPE_DOES_NOT_MATCH_FILE_TYPE = 1112
	USER_HAS_NO_PROFILE_IMAGE = 1113
	COUNTRY_NOT_SUPPORTED = 1114
	USER_OF_TABLE_OBJECT_MUST_BE_PROVIDER = 1115

	WRONG_PASSWORD = 1201
	WRONG_EMAIL_CONFIRMATION_TOKEN = 1202
	WRONG_PASSWORD_CONFIRMATION_TOKEN = 1203

	AUTH_HEADER_MISSING = 1401
	CONTENT_TYPE_HEADER_MISSING = 1402

	OLD_EMAIL_OF_USER_IS_EMPTY = 1501
	NEW_EMAIL_OF_USER_IS_EMPTY = 1502
	NEW_PASSWORD_OF_USER_IS_EMPTY = 1503

	CANNOT_USE_OLD_ACCESS_TOKEN = 1601
	ACCESS_TOKEN_MUST_BE_RENEWED = 1602

	ACCESS_TOKEN_MISSING = 2102
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
	PATH_MISSING = 2118
	METHOD_MISSING = 2119
	COMMANDS_MISSING = 2120
	ERRORS_MISSING = 2121
	ENV_VARS_MISSING = 2122
	DESCRIPTION_MISSING = 2123
	EMAIL_CONFIRMATION_TOKEN_MISSING = 2124
	PASSWORD_CONFIRMATION_TOKEN_MISSING = 2125
	COUNTRY_MISSING = 2126
	PROVIDER_NAME_MISSING = 2127
	PROVIDER_IMAGE_MISSING = 2128
	PRODUCT_NAME_MISSING = 2129
	PRODUCT_IMAGE_MISSING = 2130
	CURRENCY_MISSING = 2131

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
	PATH_WRONG_TYPE = 2225
	METHOD_WRONG_TYPE = 2226
	COMMANDS_WRONG_TYPE = 2227
	CACHING_WRONG_TYPE = 2228
	PARAMS_WRONG_TYPE = 2229
	ERRORS_WRONG_TYPE = 2230
	CODE_WRONG_TYPE = 2231
	MESSAGE_WRONG_TYPE = 2232
	ENV_VARS_WRONG_TYPE = 2233
	ENV_VAR_VALUE_WRONG_TYPE = 2234
	ACCESS_TOKEN_WRONG_TYPE = 2235
	DESCRIPTION_WRONG_TYPE = 2236
	PUBLISHED_WRONG_TYPE = 2237
	WEB_LINK_WRONG_TYPE = 2238
	GOOGLE_PLAY_LINK_WRONG_TYPE = 2239
	MICROSOFT_STORE_LINK_WRONG_TYPE = 2240
	EMAIL_CONFIRMATION_TOKEN_WRONG_TYPE = 2241
	PASSWORD_CONFIRMATION_TOKEN_WRONG_TYPE = 2242
	COUNTRY_WRONG_TYPE = 2243
	PROVIDER_NAME_WRONG_TYPE = 2244
	PROVIDER_IMAGE_WRONG_TYPE = 2245
	PRODUCT_NAME_WRONG_TYPE = 2246
	PRODUCT_IMAGE_WRONG_TYPE = 2247
	CURRENCY_WRONG_TYPE = 2248

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
	BODY_TOO_SHORT = 2314
	PATH_TOO_SHORT = 2315
	COMMANDS_TOO_SHORT = 2316
	PARAMS_TOO_SHORT = 2317
	MESSAGE_TOO_SHORT = 2318
	ENV_VAR_VALUE_TOO_SHORT = 2319
	DESCRIPTION_TOO_SHORT = 2320
	WEB_LINK_TOO_SHORT = 2321
	GOOGLE_PLAY_LINK_TOO_SHORT = 2322
	MICROSOFT_STORE_LINK_TOO_SHORT = 2323
	PROVIDER_NAME_TOO_SHORT = 2324
	PROVIDER_IMAGE_TOO_SHORT = 2325
	PRODUCT_NAME_TOO_SHORT = 2326
	PRODUCT_IMAGE_TOO_SHORT = 2327

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
	PATH_TOO_LONG = 2415
	COMMANDS_TOO_LONG = 2416
	PARAMS_TOO_LONG = 2417
	MESSAGE_TOO_LONG = 2418
	ENV_VAR_VALUE_TOO_LONG = 2419
	DESCRIPTION_TOO_LONG = 2420
	WEB_LINK_TOO_LONG = 2421
	GOOGLE_PLAY_LINK_TOO_LONG = 2422
	MICROSOFT_STORE_LINK_TOO_LONG = 2423
	PROVIDER_NAME_TOO_LONG = 2424
	PROVIDER_IMAGE_TOO_LONG = 2425
	PRODUCT_NAME_TOO_LONG = 2426
	PRODUCT_IMAGE_TOO_LONG = 2427

	EMAIL_INVALID = 2501
	NAME_INVALID = 2502
	METHOD_INVALID = 2503
	WEB_LINK_INVALID = 2504
	GOOGLE_PLAY_LINK_INVALID = 2505
	MICROSOFT_STORE_LINK_INVALID = 2506
	
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
	API_DOES_NOT_EXIST = 2809
	API_ENDPOINT_DOES_NOT_EXIST = 2810
	USER_PROFILE_IMAGE_DOES_NOT_EXIST = 2811
	PROVIDER_DOES_NOT_EXIST = 2812
	TABLE_OBJECT_PRICE_DOES_NOT_EXIST = 2813
	PURCHASE_DOES_NOT_EXIST = 2814

	TABLE_OBJECT_USER_ACCESS_ALREADY_EXISTS = 2901
	PROVIDER_ALREADY_EXISTS = 2902
	PURCHASE_ALREADY_EXISTS = 2903
end