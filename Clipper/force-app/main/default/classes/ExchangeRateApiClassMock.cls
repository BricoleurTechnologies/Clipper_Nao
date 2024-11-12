/**
 * @date May-23-2024
 * @author Bricoleur Technologies
 * @description Mock class for ExchangeRateApiClass
 */
@isTest
global class ExchangeRateApiClassMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"success":true,"timestamp":1716422399,"historical":true,"base":"AUD","date":"2024-05-22","rates":{"CNY":4.792929,"EUR":0.611449,"GBP":0.520343,"PHP":38.456881,"USD":0.661888}}');
        response.setStatusCode(200);
        return response;
    }
}