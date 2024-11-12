@isTest
public class XeroPostPurchaseOrderRequestFlowTest {

    @testSetup
    static void setup() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert testOrder;

        XeroAPISettings__c xeroAPISettings = new XeroAPISettings__c();
        xeroAPISettings.Name = Label.Xero_Setting;
        xeroAPISettings.TenantID__c = 'testTenantId';
        xeroAPISettings.Endpoint__c = 'callout:Xero_App/api.xro/2.0';
        insert xeroAPISettings;
    }

    @isTest
    static void testSendOrderToXeroFlow() {
        // Retrieve test order
        Order testOrder = [SELECT Id, AccountId FROM Order LIMIT 1];

        // Create test line item params
        XeroReqFlowLineItemParams lineItem = new XeroReqFlowLineItemParams();
        lineItem.LineItemId = 'Test LineItemId';
        lineItem.Description = 'Test Description';
        lineItem.Quantity = '1';
        lineItem.UnitAmount = '100';
        lineItem.AccountCode = '200';
        lineItem.TaxType = 'NONE';
        lineItem.TaxAmount = '0';
        lineItem.LineAmount = '100';
        lineItem.DiscountRate = '0';
        lineItem.ItemCode = 'TestItemCode';

        // Create test params
        XeroReqFlowParamsPurchaseOrder testParams = new XeroReqFlowParamsPurchaseOrder();
        testParams.SalesforceID = testOrder.Id;
        testParams.Reference = 'Test Reference';
        testParams.ContactId = 'Test ContactId';
        testParams.Date_x = String.valueOf(Date.today());
        testParams.DeliveryDate = String.valueOf(Date.today().addDays(5));
        testParams.Status = 'AUTHORISED';
        testParams.PurchaseOrderNumber = 'PO12345';
        testParams.lineItems = new List<XeroReqFlowLineItemParams>{lineItem};

        // Mock callout
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroMockHttpResponseGenerator());
        List<XeroReqFlowParamsPurchaseOrder> paramsList = new List<XeroReqFlowParamsPurchaseOrder>{testParams};
        XeroPostPurchaseOrderRequestFlow.SendOrderToXeroFlow(paramsList);
        Test.stopTest();

        // Assert that the callout was made and the data was processed
        // Add appropriate assertions based on expected outcomes
    }

    @isTest
    static void testPostPurchaseOrderAsync() {
        // Retrieve test order
        Order testOrder = [SELECT Id, AccountId FROM Order LIMIT 1];

        // Create an instance of PostPurchaseOrderAsync
        XeroPostPurchaseOrderRequestFlow.PostPurchaseOrderAsync postPurchaseOrder = new XeroPostPurchaseOrderRequestFlow.PostPurchaseOrderAsync();
        postPurchaseOrder.setSalesforceRecordId(testOrder.Id);
        postPurchaseOrder.setRequestBody('{}');
        postPurchaseOrder.setEndpoint('https://api.xero.com/testEndpoint');
        postPurchaseOrder.setRequestMethod('POST');
        postPurchaseOrder.setRequestHeader(new Map<String, String>{'Authorization' => 'Bearer testToken'});

        // Mock callout
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroMockHttpResponseGenerator());
        System.enqueueJob(postPurchaseOrder);
        Test.stopTest();

        // Assert that the job was enqueued and processed
        // Add appropriate assertions based on expected outcomes
    }

    @isTest
    static void testInit() {
        XeroPostPurchaseOrderRequestFlow.PostPurchaseOrderAsync purchaseOrder = new XeroPostPurchaseOrderRequestFlow.PostPurchaseOrderAsync ();
        purchaseOrder.initializeProperties();
        String endpoint = purchaseOrder.getEndpoint();
        Map<String , String> reqHeaderMap = purchaseOrder.getRequestHeader();
        String reqBody = purchaseOrder.getRequestBody();
        String reqMethod = purchaseOrder.getRequestMethod();
        String sfId = purchaseOrder.getSalesforceRecordId();
        String contactId = purchaseOrder.getContactID();
        purchaseOrder.setEndpoint('callout:Xero_App/api.xro/2.0');
        purchaseOrder.setRequestHeader(new Map<String , String>{'a'=>'b'});
        purchaseOrder.setRequestBody('{}');
        purchaseOrder.setRequestMethod('{}');
        purchaseOrder.setSalesforceRecordId('abcd123');
        purchaseOrder.setContactID('abcd123');
    }

    private class XeroMockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"PurchaseOrders":[{"PurchaseOrderID":"PO12345"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
}