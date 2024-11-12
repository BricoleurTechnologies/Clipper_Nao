/**
 * @date May-20-2024
 * @author Bricoleur Technologies
 * @description Class that gets the latest Historical Rates
 */
public class ExchangeRateApiClass {

    @future(callout=true)
    public static void fetchLatestExchangeRate() {

        Exchange_Rates_API_Setting__c exchangeRateApiSetting = Exchange_Rates_API_Setting__c.getValues(Constants.EXCHANGE_RATE_SETTING_NAME);
        
        if(exchangeRateApiSetting != null) {

            Exchange_Rate_Feed_Data__c erf = new Exchange_Rate_Feed_Data__c();
            Exchange_Rate_Logs__c erLog = new Exchange_Rate_Logs__c();
            String respStr;
            String statusStr;
            String retMsg;

            try {
                HttpRequest req = new HttpRequest();
                String formattedDate = DateTime.now().addDays(-1).format(Constants.EXCHANGE_RATE_DATE_FORMAT);
                String orgCurrency = UserInfo.getDefaultCurrency();
                String currStr = String.join(orgCurrencySet(), Constants.GENERIC_COMMA);
                String endpoint = exchangeRateApiSetting.Api_Url__c+
                                    formattedDate+
                                    Constants.GENERIC_QUESTION_MARK+
                                    Constants.EXCHANGE_RATE_PARAM_ACCESS_KEY+
                                    Constants.GENERIC_EQUALS+
                                    exchangeRateApiSetting.Access_Key__c+
                                    Constants.GENERIC_AMPERSAND+
                                    Constants.EXCHANGE_RATE_PARAM_BASE+
                                    Constants.GENERIC_EQUALS+
                                    orgCurrency+
                                    Constants.GENERIC_AMPERSAND+
                                    Constants.EXCHANGE_RATE_PARAM_SYMBOLS+
                                    Constants.GENERIC_EQUALS+
                                    currStr;
                                    
                req.setEndpoint(endpoint);
                req.setMethod(Constants.INTEGRATION_REST_METHOD_GET);

                Http http = new Http();
                HTTPResponse res = http.send(req);
                respStr = res.getBody();
                statusStr = Constants.GENERIC_BLANK;

                if(String.isNotBlank(respStr)) {
                    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(respStr);

                    if(dataMap != null) {
                        statusStr = dataMap.containsKey(Constants.EXCHANGE_RATE_JSON_ERROR)?Constants.EXCHANGE_RATE_FEED_STATUS_FAILED:Constants.EXCHANGE_RATE_FEED_STATUS_RETRIEVED;
                        if(dataMap.containsKey(Constants.EXCHANGE_RATE_JSON_ERROR)) {
                            retMsg = deserializeJSON(respStr, Constants.EXCHANGE_RATE_JSON_ERROR, Constants.EXCHANGE_RATE_JSON_MESSAGE);
                            erLog = exchangeRateLog(respStr, statusStr, retMsg);
                        }    
                        else {
                            erf.Exchange_Rate_JSON__c = respStr;
                            erf.Status__c = statusStr;
                        }
                    }
                }
                System.debug('respStr bric '+respStr); 
                
                if(erf != null) {
                    insert erf;
                }
            }
            catch(System.CalloutException e) {
                retMsg = retMsg+'\n\n'+e.getMessage();
                retMsg = retMsg.replace('null', Constants.GENERIC_BLANK).trim();
                erLog = exchangeRateLog(respStr, statusStr, retMsg);
            }

            if(erLog != null) {
                insert erLog;
            }
        }
    }

    public static Exchange_Rate_Logs__c exchangeRateLog(String resp, String status, String returnMsg) {
        Exchange_Rate_Logs__c erLogs = new Exchange_Rate_Logs__c(
            Log_Date__c = System.now(),
            Response__c = resp,
            Status__c = status,
            Return_Message__c = returnMsg
        );
        return erLogs;
    }

    public static String deserializeJSON(String jsonString, String key, String fieldStr)
    {
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        Map<String, Object> jsonObjNames = (Map<String, Object>) result.get(key);
        //Map<String, Object> jsonObj = (Map<String, Object>) jsonObjNames[0];
        return String.valueOf(jsonObjNames.get(fieldStr));
    }

    public static Set<String> orgCurrencySet() {
        Set<String> orgCurrSet = new Set<String>();
        for(CurrencyType curr : [SELECT IsoCode FROM CurrencyType WHERE IsActive = true AND IsCorporate = false]) {
            orgCurrSet.add(curr.IsoCode);
        }
        return orgCurrSet;
    }
}