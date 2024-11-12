/*
* Author: Bricoleur Technologies - John Paulo M. Sulit (jp@bricoleurtech.com)
* Created Date: Dec 15, 2023
* Description: Mock callout class for OnlineQuoteFormControllerTest_Bric
* History: 	Dec 15, 2023 - Created
*/

@isTest
global class UserLocationMock_Bric implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest request) 
    {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"ip":"120.29.77.43","hostname":"43.77.29.120-rev.convergeict.com","city":"Angeles City","region":"Central Luzon","country":"PH","loc":"15.1500,120.5833","org":"AS17639 Converge ICT Solutions Inc.","postal":"2009","timezone":"Asia/Manila","readme":"https://ipinfo.io/missingauth"}');
        response.setStatusCode(200);
        return response; 
    }
}