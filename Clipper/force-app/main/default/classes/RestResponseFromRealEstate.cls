public class RestResponseFromRealEstate{
    public class GetEnquiryResponseBody
    {
	public embeddeds embedded;
	//public link links;
    }
	public class embeddeds {
		public List<enquirie> enquiries;
	
    }
	public class enquirie {
		public String id;	//80erpo30-2e24-4bea-842c-9df71f90brtl
		public String agencyId;	//ABCDEF
		public String receivedAt;	//2017-07-24T10:58:32.000Z
		public String processedAt;	//2017-07-26T03:21:25.090Z
		public String type;	//REALESTATECOMAULISTING
		public String comments;	//Hi there I'm interested in getting some more information on the property...
		public List<string> agentRecipients;
		public List<string> requestedInformation;
		public cls_listing listing;
		public cls_contactDetails contactDetails;
		public link links;
	}
	
/*	public class cls_agentRecipients {
		public String email;	//a
	}*/
	/*class cls_suppliedMarketStatus {
	}*/
	public class cls_listing {
		public String id;	//100012345
		public String externalListingId;	//PARTNER_12345
		//public cls_parentId parentId;
	}
	public class cls_contactDetails {
		public String fullName;	//Sarah Smith
		public String email;	//sarah@example.com
		public String phone;	//0401234567
		public String postcode;	//4020
		public String preferredContactMethod;	//PHONE
	}
	public class link {
		public cls_self self;
		public cls_next next;
	}
	public class cls_self {
		public String href;	//https://api.realestate.com.au/lead/v1/enquiries?partner_id=12345678-2356-48a7-b41a-b766294c1baf&since=2010-09-06T12:27:00.1Z
	}
	public class cls_next {
		public String href;	//https://api.realestate.com.au/lead/v1/enquiries?partner_id=12345678-2356-48a7-b41a-b766294c1baf&page=NDE4NC_xRdy3eH4yc1i-T5D_ZRu9djEvNDE=
	}
	public static RestResponseFromRealEstate parse(String json){
		return (RestResponseFromRealEstate) System.JSON.deserialize(json, RestResponseFromRealEstate.class);
	}

	
}