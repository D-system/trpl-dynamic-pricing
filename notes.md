## Initial assessment:
- The repository uses an old version of Ruby. It could be updated to 4.0.6 without any issues (probably).
- Rails too is old. At the commit time, Rails 8.0 was release 10 months prior. Probably a copy/paste from an old project. It would be valuable to update it to at least Rails 7.2.
- The database is SQLite. Cool, no installation. But there's no (real) tables.
- The error handling validates all the parameters presences at once but the integrity is checked one by one and stop at the first error. It could validate all parameters before returning the error.
- The API returns 500 error when the external rate-api is down. The output is in json. Nice! ... But looking at the logs, the crash is due to a method used on a nil object. Also Rails is configured in API mode, so it can only returns JSON.
- By checking the Gems (with bundler-audit), there are 109 open CVEs (15 critical CVEs) from 14 different Gems.
- After installing the Docker and Colima, I tested with the rate-api server. It failed at first run and requests were successful after that.
- The services have a BaseService class to have the same common behavior. Nice.

## Later observations
- The code coverage is at 96.15%. It is missing the method that do the actual HTTP request. It would be nice to have that method tested too as any change to the method or the gem could break the code without noticing it due to lack of testing.
- I was implementing the test for the RateApiClient when I realised that the JSON parsing is performed in the Api::V1::PricingService. It would be better to test the there because there is logic. RateApiClient is sort of alias for HTTParty.
- I realised that the JSON parsing is done twice. Once manually with `JSON.parse` and another one done automatically from HTTParty when the content-type header is set properly
- The test for the `Api::V1::PricingControllerTest` is testing somewhat too deep or the not deep enough.
- - It uses the `Api::V1::PricingService` that internally call `RateApiClient` that is stubbed in the controller test. It doesn't provide the expected object (on HTTParty object) that implement all methods available. Either it should intercept and mock the HTTP or stub `Api::V1::PricingService` with the `result` set.
- - The `Api::V1::PricingControllerTest`'s `mock_body`'s rate doesn't have the right type (string vs integer/number).


## Plan:

### Mandatory changes:
- [x] Block any HTTP calls in test
- [] Api::V1::PricingService: Add test to conver successful request to the rate-api but with unexpected object
- [] Api::V1::PricingService: validate object
- [] Api::V1::PricingService: Add a cache

### Other changes (nice to have):
- [x] Update Docker commands in the README
- [x] Add code coverage metrics
- [x] Make the test suite fail if below minimum coverage
- [] Update minimum branch coverage to 100%
- [] Add test for RateApiClient#get_rate
- [] Update (non-Rails) Gems
- [] Update Rails to latest in 7.x
- [] Update Ruby
- [] Update Rails to latest (8.x)
- [] Have proper translations for the error messages
- [] Validate all Api::V1::PricingService parameters at once
