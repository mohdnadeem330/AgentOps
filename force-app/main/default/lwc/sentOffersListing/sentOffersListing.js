import { LightningElement, track } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
import getActivityHistory from '@salesforce/apex/SentOffersListingController.getActivityHistory';


export default class SentOffersListing extends LightningElement {

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    @track data;
    @track sortBy;
    @track sortDirection;
    exportIcon = resourcesPath + "/ALDARResources/svg/ExportIcon.svg";


    tableColumns=[
        {
            sortable: true,
            type: 'text',
            fieldName: 'firstName',
            label: 'First Name',
            // initialWidth: 200,
        },
        {
            sortable: true,
            type: 'text',
            fieldName: 'lastName',
            label: 'Last Name',
            // initialWidth: 200,
        },
        {
            sortable: true,
            type: 'text',
            fieldName: 'email',
            label: 'Email',
            // initialWidth: 200,
        },
        {
            sortable: true,
            type: 'text',
            fieldName: 'PropertyName',
            label: 'Property Name',
            // initialWidth: 200,
        },
        {
            sortable: true,
            type: 'text',
            fieldName: 'unitCode',
            label: 'Unit Code',
            // initialWidth: 200,
        },
        {
            sortable: true,
            type: 'text',
            fieldName: 'sentDate',
            label: 'Sent Date',
            // initialWidth: 200,
        }
    ]

    get getStyle(){

        return (this.selectedRows?.length <1 || this.selectedRows == undefined )   ?"pointer-events: none;opacity:0.5;":"pointer-events: unset;opacity:1;";
         
    }

    connectedCallback(){
        this.resetAll();
    }

    async resetAll() {
        console.log('resetall');

        let newTableData = [];

        const newData = await getActivityHistory();

        for (let i = 0; i < newData.length; i++) {
            newTableData.push(newData[i]);
        }
        this.data = newTableData;

    }

    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.data));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.data = parseData;

    }

    exportToCSV() {  
        let columnHeader = ["First Name","Last Name", "Email", "Property Name", "Unit Code","Sent Date"];  // This array holds the Column headers to be displayd

        let jsonKeys = ["firstName","lastName","email","PropertyName","unitCode","sentDate"]; // This array holds the keys in the json data  
        var jsonRecordsData = this.data;  
        let csvIterativeData;  
        let csvSeperator ; 
        let newLineCharacter;  
        csvSeperator = ",";  
        newLineCharacter = "\n";  
        csvIterativeData = "";  
        csvIterativeData += columnHeader.join(csvSeperator);  
        csvIterativeData += newLineCharacter;  
        for (let i = 0; i < jsonRecordsData.length; i++) {  
          let counter = 0;  
          for (let iteratorObj in jsonKeys) {  
            let dataKey = jsonKeys[iteratorObj];  
            if (counter > 0) {  csvIterativeData += csvSeperator;  }  
            if (  jsonRecordsData[i][dataKey] !== null &&  
              jsonRecordsData[i][dataKey] !== undefined  
            ) {  csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';  
            } else {  csvIterativeData += '""';  
            }  
            counter++;  
          }  
          csvIterativeData += newLineCharacter;  
        }  
        this.hrefdata = "data:text/csv;charset=utf-8," + encodeURI(csvIterativeData);  
        csvIterativeData = csvIterativeData.replace(/"/g, '');

        var downloadLink = document.createElement("a"); 
        document.body.appendChild(downloadLink);
        downloadLink.href = 'data:application/vnd.ms-excel,'+csvIterativeData;
        downloadLink.download = 'Sent Offers.xls.csv';
        downloadLink.click();
    }  

    tableData=
    [
        {
firstName:"Test",
lastName:"Test",
emailShouldBemasked:"Test",
projectName:"Test",
sentDate:"Test"
        },

        {
            firstName:"Test",
            lastName:"Test",
            emailShouldBemasked:"Test",
            projectName:"Test",
            sentDate:"Test"
                    },
                    {
                        firstName:"Test",
                        lastName:"Test",
                        emailShouldBemasked:"Test",
                        projectName:"Test",
                        sentDate:"Test"
                                },
                                {
                                    firstName:"Test",
                                    lastName:"Test",
                                    emailShouldBemasked:"Test",
                                    projectName:"Test",
                                    sentDate:"Test"
                                            },
                                            {
                                                firstName:"Test",
                                                lastName:"Test",
                                                emailShouldBemasked:"Test",
                                                projectName:"Test",
                                                sentDate:"Test"
                                                        },
                                                        {
                                                            firstName:"Test",
                                                            lastName:"Test",
                                                            emailShouldBemasked:"Test",
                                                            projectName:"Test",
                                                            sentDate:"Test"
                                                                    },
                                                                    {
                                                                        firstName:"Test",
                                                                        lastName:"Test",
                                                                        emailShouldBemasked:"Test",
                                                                        projectName:"Test",
                                                                        sentDate:"Test"
                                                                                },
                                                                                {
                                                                                    firstName:"Test",
                                                                                    lastName:"Test",
                                                                                    emailShouldBemasked:"Test",
                                                                                    projectName:"Test",
                                                                                    sentDate:"Test"
                                                                                            },
                                                                                            {
                                                                                                firstName:"Test",
                                                                                                lastName:"Test",
                                                                                                emailShouldBemasked:"Test",
                                                                                                projectName:"Test",
                                                                                                sentDate:"Test"
                                                                                                        }
                                                                                
    ]

  get dataSize(){
      return this.data?.length == 0 || this.data == undefined;
  }  
}