/*
API : 52
Source : lwcFactory.com
*/
import {LightningElement,api, wire, track} from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
//Import apex method 
//import fetchContacts from '@salesforce/apex/.fetchContacts';

export default class locationProductDataTableWithPagination extends LightningElement {
     @api inputValue;
     @api selectedRecords=[];
     @api outputValue;
     
  
    // JS Properties 
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    records = []; //All records available in the data table
    columns = []; //columns information available in the data table
    totalRecords = 0; //Total no.of records
    pageSize; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page
    

    get bDisableFirst() {
        return this.pageNumber == 1;
    }

    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    // connectedCallback method called when the element is inserted into a document
    connectedCallback() {
        console.log('***'+JSON.stringify(this.inputValue));
   this.records=this.inputValue;
        // set datatable columns info
        this.columns = [{
                label: 'Ware House Location',
                fieldName: 'Warehouse_Location__c'
            },
           
        ];
         this.totalRecords = this.records.length; // update total records count                 
                    this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option
                    this.paginationHelper(); // call helper menthod to update pagination logic 

        // fetch contact records from apex method 
        /*fetchContacts()
            .then((result) => {
                if (result != null) {
                    console.log('RESULT--> ' + JSON.stringify(result));
                    this.records = result;
                   
                }
            })
            .catch((error) => {
                console.log('error while fetch contacts--> ' + JSON.stringify(error));
            });*/
    }
    getSelectedName(event){
                const selectedRows = event.detail.selectedRows;
                this.selectedRecords=selectedRows;
      this.dispatchEvent(new FlowAttributeChangeEvent('outputValue', this.selectedRecords));
        //console.log('@@@'+JSON.stringify(selectedRecords));
    }

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }


    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }

        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.records[i]);
        }
    }
}