/**
 * @date May-23-2024
 * @author Bricoleur Technologies
 * @description Error mock class for ExchangeRateApiClass
 */
@isTest
global class ExchangeRateApiErrorMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"error":{"code":"invalid_date","message":"You have entered an invalid date. [Required format: date=YYYY-MM-DD]"}}');
        response.setStatusCode(404);
        return response;
        //throw new CalloutException('Simulated callout exception');
    }
}