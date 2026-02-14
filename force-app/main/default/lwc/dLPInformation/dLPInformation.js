import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import dlpZoneRetrieve from '@salesforce/apex/DLPZoneController.dlpZoneRetrieve';
import checkJointAccount from '@salesforce/apex/DLPZoneController.CheckJointRelationAccount';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case'; // Adjust this to your object
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import accountNameLabel from '@salesforce/label/c.Visitor_Account';



export default class DlpZoneInfo extends NavigationMixin(LightningElement) {

	checkduplicate;
	loaded = true;
	@api recordId; // Account Id
	dlpZoneList;
	AccountName
	@track showModal = false
	@track showModalContent = false
	@track isModalOpen = false;
	activeSections = ['B'];
	recordTypes=[];
	isNewButtonVisible =false;
	@track columns = [
		{
			label: 'CaseNumber',
			fieldName: 'Id',
			type: 'url',
			sortable: true,
			typeAttributes: { label: { fieldName: 'CaseNumber' } },
		},
		// {
		// 		label: 'Subject',
		// 		fieldName: 'Subject',
		// 		type: 'text',
		// 		sortable: true
		// },
		{
			label: 'Category',
			fieldName: 'CaseCategory__c',
			type: 'text',
			sortable: true
		},
		{
			label: 'Owner',
			fieldName: 'CaseOwner',
			type: 'text',
			sortable: true
		},
		{
			label: 'Assigned To',
			fieldName: 'Assigned_To',
			type: 'text',
			sortable: true
		},
		{
			label: 'CreatedDate',
			fieldName: 'CreatedDate',
			type: 'Date',
			sortable: true
		},
		// 	{
		// 		label: 'DLP Agent',
		// 		fieldName: 'Assigned_Service_Executive__c',
		// 		type: 'text',
		// 		sortable: true
		// }, 
		{
			label: 'Status',
			fieldName: 'Status',
			type: 'text',
			sortable: true
		},
	];

	@track offLineCols = [
		{
			label: 'ProductName',
			fieldName: 'Id',
			type: 'url',
			sortable: true,
			typeAttributes: { label: { fieldName: 'ProductName' } },
			wrapText: true
		},
		{
			label: 'UOM',
			fieldName: 'UOM',
			type: 'string',
			sortable: false,
			wrapText: true
		},

		{
			label: 'Quantity',
			fieldName: 'QuantityOnHand__c',
			type: 'number',
			sortable: true,
			wrapText: true
		},
		{
			label: 'Consumed Qty.',
			fieldName: 'ConsumedQuantity__c',
			type: 'number',
			sortable: true,
			wrapText: true
		},
		{
			label: 'In Progress Qty.',
			fieldName: 'QuantityInProgress__c',
			type: 'number',
			sortable: true,
			wrapText: true
		},
		{
			label: 'Balance Qty.',
			fieldName: 'BalanceQuantity__c',
			type: 'number',
			sortable: true,
			wrapText: true
		},
		{
			type: "button", label: 'Action', initialWidth: 100, typeAttributes: {
				label: ' Case',
				name: 'New Case',
				title: 'New Case',
				disabled: false,
				value: 'New Case',
				iconPosition: 'left',
				iconName: 'action:new_case',
				variant: 'Brand',
				rowActions: { label: 'Custom Action', name: 'custom_action' }
			}
		},

	];

	@wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.recordTypes = Object.values(data.recordTypeInfos)
                .filter(recordTypeInfo => !recordTypeInfo.master)
                .map(recordTypeInfo => ({
                    value: recordTypeInfo.recordTypeId,
                    label: recordTypeInfo.name
                }));

            this.error = undefined;
        } else if (error) {

            this.error = error;
            this.recordTypes = undefined;
        }
    }
	@wire(getRecord, { recordId: '$recordId',fields: [ACCOUNT_NAME_FIELD]})
        accountDetail({data, error})
        {
            if(data){
                this.AccountName = data.fields.Name.value;
				console.log('AccountName'+this.AccountName);
                
            }
        }

	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		if (row.BalanceQuantity__c <= 0) {
			const event = new ShowToastEvent({
				title: 'Error',
				message: 'There are no balance quantity to create a request',
				variant: 'error',
				mode: 'dismissable'
			});
			this.dispatchEvent(event);
			return;
		}

		switch (actionName) {
			case 'New Case':
				this.navigateToNewOnDemandRecordPage(event);
				break;
			default:
		}
	}
	connectedCallback() {
		//super();
		console.log('Connected Call back called');
		if(this.recordId === accountNameLabel)
			{
           this.isNewButtonVisible =true;
			}
		this.handleSearch();
	}
	closeModal() {
		// to close modal set isModalOpen tarck value as false
		this.isModalOpen = false;
	}

	handleSearch() {
		console.log('result', this.recordId);
		dlpZoneRetrieve({ accid: this.recordId })
			.then((result) => {

				console.log('result', result);
				console.log('result-1',JSON.stringify(result));
				let accParsedData = JSON.parse(JSON.stringify(result));

				accParsedData.forEach(acc => {
					acc.lstOfferLines.forEach(ele => {
						ele.Id = '/' + ele.Id;
						if (ele.Product_Item__c) {
							ele.ProductName = ele.Product_Item__r.Product2.Name;
							ele.UOM = ele.Product_Item__r.Product2.QuantityUnitOfMeasure;
						}
					});
					acc.caseRelatedToUnit.forEach(caseitem => {
						caseitem.Id = '/' + caseitem.Id;
						if (caseitem.Account) {
							console.log('acc', caseitem.Account);
							caseitem.AccountId = caseitem.Account.Name;
							caseitem.CaseOwner = caseitem.Owner.Name;

						}
						if (caseitem.Assigned_To__r) {
							caseitem.Assigned_To = caseitem.Assigned_To__r.Name;
						}

						if (caseitem.Assigned_Service_Executive__r) {
							caseitem.Assigned_Service_Executive__c = caseitem.Assigned_Service_Executive__r.Name;
						}
					});

				});

				if (accParsedData != '') {
					this.dlpZoneList = accParsedData;
				}
				this.loaded = !this.loaded;
				//this.error = undefined;
			})
			.catch((error) => {
				this.loaded = !this.loaded;
				//this.error = error;
				//this.contacts = undefined;
			});
	}
	openCasesModel(event) {
		this.isModalOpen = true;
	}
	handleOpenRecord(event) {

		let objId = event.target.dataset.id;
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: objId,
				objectApiName: 'Unit__c',
				actionName: 'view',

			},
			state: {

			},
		});
	}

	navigateToNewOnDemandRecordPage(event) {
		//alert('case');
		const amcRecType = this.recordTypes.find(ele => ele.label === 'AMC');

		let row = event.detail.row;
		const defaultValues = encodeDefaultFieldValues({
			Unit__c: row.SalesOrder__r.Unit__c,
			AccountId: this.recordId,
			ProductId: row.Product_Item__r.Product2Id,
			SalesOrder__c: row.SalesOrder__c,
			Vertical__c: 'DLP',
			SubVertical__c: 'AMC',
			CaseCategory__c:'On Demand',
			SubCategory__c:row.ProductName,
			ResolutionType__c: 'Maintenance',
			Subject:'AMC On Demand'+row.ProductName
		});
		this[NavigationMixin.Navigate](
			{
				type: "standard__objectPage",
				attributes: {
					objectApiName: "Case",
					actionName: "new",
				},
				state: {
					defaultFieldValues: defaultValues,
					recordTypeId: amcRecType.value
				},

			},
			false,
		);

	}

	navigateToNewRecordPage(event) {
		const recTypeId  = this.recordTypes.find(ele => ele.label === 'DLP');
		let unitId = event.target.dataset.id;
		const defaultValues = encodeDefaultFieldValues({
			Unit__c: unitId,
			AccountId: this.recordId,
		});
		this[NavigationMixin.Navigate](
			{
				type: "standard__objectPage",
				attributes: {
					objectApiName: "Case",
					actionName: "new",
				},
				state: {
					defaultFieldValues: defaultValues,
					recordTypeId: recTypeId.value
				},

			},
			false,
		);

	}

    navigateToCreateTestTenantCase(event) {
				const defaultValues = encodeDefaultFieldValues({
			AccountId: this.recordId,
		});		
		this[NavigationMixin.Navigate]({
			type: 'standard__component',
			attributes: {
				componentName: 'c__createNewCase',
			},
			state: {
				c__AccountId: this.recordId,
				c__CustomerType : 'Others',
				c__UnitId: null,
				c__checkJointAccount : false
			}
		});

}

	navigateToCreateTestVisitorCase(event) {
		console.log('RecordId'+this.recordId);
		console.log('Accountlabel==='+accountNameLabel);
		if(this.recordId == accountNameLabel)
		{
        console.log('Test DlpInformation');
		const defaultValues = encodeDefaultFieldValues({
			AccountId: this.recordId,
		});		
		this[NavigationMixin.Navigate]({
			type: 'standard__component',
			attributes: {
				componentName: 'c__createNewCase',
			},
			state: {
				c__AccountId: this.recordId,
				c__CustomerType : 'Visitor',
				c__UnitId: null,
				c__checkJointAccount : false
			}
		});
	}
else{

	const event = new ShowToastEvent({
		title: 'Error',
		message: 'Without Unit can not create Case',
		variant: 'error',
		mode: 'dismissable'
	});
	this.dispatchEvent(event);
}
}


	navigateToNewCasePage(event) {
        let unitId = event.target.dataset.id;
		checkJointAccount({ accountId: this.recordId })
			.then((result) => {
				
                this.checkduplicate = JSON.stringify(result);
				
				
				//  const defaultValues = encodeDefaultFieldValues({
				//  	Unit__c: unitId,
				//  	AccountId: this.recordId,
				//  });
				 console.log('Check Duplicate Value'+this.checkduplicate);
				 console.log('unitId'+unitId);
				 this[NavigationMixin.Navigate]({
				 	// Pass in pageReference
				 	type: 'standard__component',
				 	attributes: {
				 	componentName: 'c__createNewCase',
				 	},
				 	state: {
			 			c__UnitId: unitId,
				 		c__AccountId: this.recordId,
				 		c__CustomerType : 'NotVisitor',
				 		c__checkJointAccount : this.checkduplicate
				 	}
				 });

			}).catch({

			})
		// let unitId = event.target.dataset.id;
		// const defaultValues = encodeDefaultFieldValues({
		// 	Unit__c: unitId,
		// 	AccountId: this.recordId,
		// });
		// console.log('Check Duplicate Value'+this.checkduplicate);
		// this[NavigationMixin.Navigate]({
		// 	// Pass in pageReference
		// 	type: 'standard__component',
		// 	attributes: {
		// 		componentName: 'c__createNewCase',
		// 	},
		// 	state: {
		// 		c__UnitId: unitId,
		// 		c__AccountId: this.recordId,
		// 		c__CustomerType : 'NotVisitor',
		// 		c__checkJointAccount : this.checkduplicate
		// 	}
		// });
	}



	closeModal() {
		this.showModal = false;
		this.showModalContent = false;
	}


	handleOpenSORecord(event) {
		let objId = event.target.dataset.id;
		//alert(objId);
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: objId,
				objectApiName: 'SalesOrder__c',
				actionName: 'view',
			},
			state: {
				// You can pass additional parameters if needed
			},
		});
	}


	exportToCSV(event) {

		let row = event.target.dataset.id;
		let tempArr = this.dlpZoneList;
		let filArr = [];
		for(let i of this.dlpZoneList){
			if( i.soId == row){
				for(let j of i.lstOfferLines){
					let obj = {'Unit':i.unitName,'Product Name':j.ProductName,'UOM':j.Product__r.QuantityUnitOfMeasure,'Quantity':j.Quantity__c,'Balance Quantity':j.BalanceQuantity__c,'Consumed Quantity':j.ConsumedQuantity__c,'Quantity In Progress':j.QuantityInProgress__c};
					filArr.push(obj);
				}
				break;
			}
		}
			
			 

		let csv = this.convertArrayToCSV(filArr);
		let downloadElement = document.createElement('a');
		downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
		downloadElement.target = '_self';
		downloadElement.download = 'DataTableExport.csv';
		document.body.appendChild(downloadElement);
		downloadElement.click();
	}

	convertArrayToCSV(data) {
		const columnHeaders = Object.keys(data[0]);
		const csvRows = [];
		csvRows.push(columnHeaders.join(','));

		data.forEach(row => {
			const values = columnHeaders.map(header => {
				let value = row[header] ? row[header] : '';
				value = value.toString().replace(/"/g, '""');
				return `"${value}"`;
			});
			csvRows.push(values.join(','));
		});

		return csvRows.join('\n');
	}
}