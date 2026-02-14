import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import { getRecord, createRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import account_OBJECT from "@salesforce/schema/Account"; // Replace with your actual object
import case_OBJECT from "@salesforce/schema/Case"; // Replace with your actual object
import userId from "@salesforce/user/Id";
import ACCOUNT_NAME from "@salesforce/schema/Customer_Unit__c.Account__r.Name";
import ASSET_NAME from "@salesforce/schema/Customer_Unit__c.Unit__r.Name";
import ASSET_floorNumber from "@salesforce/schema/Customer_Unit__c.Unit__r.ECSS_Floor_Number__c";
import ASSET_bedroomNumber from "@salesforce/schema/Customer_Unit__c.Unit__r.ECSS_Number_of_Bedrooms__c";
import ASSET_linkedProject from "@salesforce/schema/Customer_Unit__c.Unit__r.ECSS_Project__r.Name";
import ASSET_linkedBuilding from "@salesforce/schema/Customer_Unit__c.Unit__r.ECSS_Building_Section__r.Name";
import ACCOUNT_LOOKUP from "@salesforce/schema/Customer_Unit__c.Account__c"; // Lookup field
import ASSET_LOOKUP from "@salesforce/schema/Customer_Unit__c.Unit__c"; // Lookup field
import NAME_FIELD from "@salesforce/schema/Customer_Unit__c.Name"; // Field for Customer Unit Name
import getRecTypes from "@salesforce/apex/ECSS_CaseCreationController.ecssCaseRecordTypes";
import insertDocuments from "@salesforce/apex/ECSS_TestCategorySubCategoryController.insertDocuments";
import getAccRecTypes from "@salesforce/apex/ECSS_CaseCreationController.ecssAccountRecordTypes";
import getRelatedAcc from "@salesforce/apex/ECSS_CaseCreationController.getRelatedAccount";
import getRelatedContacts from "@salesforce/apex/ECSS_CaseCreationController.relatedContacts";
import getKhidmahContracts from "@salesforce/apex/ECSS_CaseCreationController.getKhidmahContracts";
import phoneValidaty from "@salesforce/apex/ECSS_CaseCreationController.phoneValidaty";
import getAccRecord from "@salesforce/apex/ECSS_CaseCreationController.getAccRecord";
import getSalutationValues from "@salesforce/apex/ECSS_CaseCreationController.getSalutationValues";
import getCountryValues from "@salesforce/apex/ECSS_CaseCreationController.getCountryValues";
import getNationalityValues from "@salesforce/apex/ECSS_CaseCreationController.getNationalityValues";

import getInvValues from "@salesforce/apex/ECSS_CaseCreationController.getInvData";

import getCompanyFromManagedBy from "@salesforce/apex/ECSS_CaseCreationController.getCompanyFromManagedBy";
import accDuplicateCheck from "@salesforce/apex/ECSS_CaseCreationController.accDuplicateCheck";
import contactDuplicateCheck from "@salesforce/apex/ECSS_CaseCreationController.contactDuplicateCheck";
import contactDuplicateRetrieval from "@salesforce/apex/ECSS_CaseCreationController.contactDuplicateRetrieval";

import subCategoryValues from "@salesforce/apex/ECSS_CaseCreationController.subCategoryReturnValue";
import objectCategoryValues from "@salesforce/apex/ECSS_CaseCreationController.objectCategoryReturnValue";
import categoryReturnValues from "@salesforce/apex/ECSS_CaseCreationController.categoryReturnValue";
import categoryValues from "@salesforce/apex/ECSS_TestCategorySubCategoryController.getCategoryProjectMap";
import ECSS_UNIT from "@salesforce/schema/Case.AssetId";
import ECSS_CONTRACT from "@salesforce/schema/Case.ECSS_Contract__c";
import ECSS_Company from "@salesforce/schema/Case.ECSS_CompanyOptions__c";
import ECSS_CONTRACT_START from "@salesforce/schema/Case.ECSS_Contract_Start_Date__c";
import ECSS_CONTRACT_END from "@salesforce/schema/Case.ECSS_Contract_End_Date__c";
import ECSS_NUM_CALLOUTS from "@salesforce/schema/Case.ECSS_Number_of_call_outs__c";
import ECSS_KHIDMAH_CONT_TYPES from "@salesforce/schema/Case.ECSS_Khidmah_Contract_Type__c";
import ECSS_RequestedAccountName from "@salesforce/schema/Case.ECSS_RequestedAccountName__c";
import ECSS_RequestedEmail from "@salesforce/schema/Case.ECSS_RequestedEmail__c";
import ECSS_RequestedEmiratesId from "@salesforce/schema/Case.ECSS_RequestedEmiratesId__c";
import ECSS_RequestedMobileCountryCode from "@salesforce/schema/Case.ECSS_RequestedMobileCountryCode__c";
import ECSS_RequestedMobileNumber from "@salesforce/schema/Case.ECSS_RequestedMobileNumber__c";
import ECSS_RequestedPassportNo from "@salesforce/schema/Case.ECSS_RequestedPassportNo__c";
import ECSS_RequestedRegistractionNumber from "@salesforce/schema/Case.ECSS_RequestedRegistractionNumber__c";
import ECSS_NonExistingCustomerApprovalPending from "@salesforce/schema/Case.ECSS_NonExistingCustomerApprovalPending__c";
import ECSS_contactId from "@salesforce/schema/Case.ContactId";
import ECSS_Status from "@salesforce/schema/Case.Status";
import ECSS_contactIdSelected from "@salesforce/schema/Case.ECSS_contactIdSelected__c";
import ECSS_NewContactRelationship from "@salesforce/schema/Case.ECSS_NewContactRelationship__c";
import ECSS_CONTRACT_DETAILS_SELECTION_SKIPPED from "@salesforce/schema/Case.ECSS_Contract_Details_Selection_Skipped__c";
import ECSS_CONTRACT_DETAILS_ID from "@salesforce/schema/Case.ECSS_Contract_Details_Id__c";
import ECSS_Replacement from "@salesforce/schema/Case.ECSS_Replacement__c";
import ECSS_AccountCreationType from "@salesforce/schema/Case.ECSS_AccountCreationType__c";
import ECSS_NewAdditionalCardNeeded from "@salesforce/schema/Case.ECSS_NewAdditionalCardNeeded__c";
import ECSS_ReprogrammingNeeded from "@salesforce/schema/Case.ECSS_ReprogrammingNeeded__c";
import ECSS_Created_From_Component from "@salesforce/schema/Case.ECSS_Created_From_Component__c";
import ECSS_Req_Acc_Type from "@salesforce/schema/Case.ECSS_Req_Acc_Type__c";
import ECSS_CASE_SUB_CATEGORY from "@salesforce/schema/Case.ECSS_Sub_Category_Text__c";
import ECSS_CASE_OBJECT_CATEGORY from "@salesforce/schema/Case.ECSS_Object_Category__c";
import ECSS_Account_Contract_Request from "@salesforce/schema/Case.ECSS_Account_Contract_Request__c";
import ECSS_AccountSalutation from "@salesforce/schema/Case.ECSS_AccountCreationSalutation__c";
import ECSS_AccountCountry from "@salesforce/schema/Case.ECSS_OrganizationBillingCountry__c";
import ECSS_AccountNationality from "@salesforce/schema/Case.ECSS_AccountCreationNationality__c";
import ECSS_Top_Up_Contract from "@salesforce/schema/Case.ECSS_Top_Up_Contract__c";
import ECSS_isCaseApproved from "@salesforce/schema/Case.ECSS_isCaseApproved__c";
import ECSS_CaseCustomerType from "@salesforce/schema/Case.CustomerType__c";

//import derivedValues from '@salesforce/apex/ECSS_CaseCreationController.derivedValues';
import caseRecId from "@salesforce/schema/Case.Id";

import Description from "@salesforce/schema/Case.Description";
import recordType from "@salesforce/schema/Case.RecordTypeId";
import subVertical from "@salesforce/schema/Case.SubVertical__c";
import caseCategory from "@salesforce/schema/Case.CaseCategory__c";
import subCategory from "@salesforce/schema/Case.ECSS_Sub_Category_Text__c";
import caseOrigin from "@salesforce/schema/Case.Origin";
import caseSubject from "@salesforce/schema/Case.Subject";
import ECSS_EmergencyCase from "@salesforce/schema/Case.ECSS_EmergencyCase__c";
import ECSS_Account from "@salesforce/schema/Case.AccountId";
//import getCustomerUnits from '@salesforce/apex/ECSS_CustomerUnitController.getRelatedUnits';
import getCustomerUnits from "@salesforce/apex/ECSS_CaseCreationController.getRelatedUnits";
//import getrecordtypeName from "@salesforce/apex/ECSS_CaseCreationController.getrecordtypeName";

//Fields for account
import ECSS_AccountFirstName from "@salesforce/schema/Case.ECSS_AccountFirstName__c";
import ECSS_AccountLastName from "@salesforce/schema/Case.ECSS_AccountLastName__c";
1;
import ECSS_PackageType from "@salesforce/schema/Case.ECSS_PackageType__c";
import ECSS_ContractReceiptNumber from "@salesforce/schema/Case.ECSS_ContractReceiptNumber__c";
import ECSS_AccountMiddleName from "@salesforce/schema/Case.ECSS_AccountMiddleName__c";
import FCR from "@salesforce/schema/Case.FCR__c";
import ECSS_AccountBuildingSection from "@salesforce/schema/Case.ECSS_AccountBuildingSection__c";
import ECSS_AccountUnit from "@salesforce/schema/Case.ECSS_AccountUnit__c";
import ECSS_Floor from "@salesforce/schema/Case.ECSS_Floor__c";
import ECSS_ApartmentNumber from "@salesforce/schema/Case.ECSS_ApartmentNumber__c";
import ECSS_AccountStreetName from "@salesforce/schema/Case.ECSS_AccountStreetName__c";
import ECSS_AccountStreeNo from "@salesforce/schema/Case.ECSS_AccountStreetNo__c";
import ECSS_ZipCode__c from "@salesforce/schema/Case.ECSS_ZipCode__c";
import ECSS_CreateAccount from "@salesforce/schema/Case.ECSS_CreateAccount__c";
import ECSparentCaseId from "@salesforce/schema/Case.ParentId";

//Field imports for unit selection
import UnitNAME_FIELD from "@salesforce/schema/Asset.Name"; // Field for Customer Unit Name
import UnitFloorNumbers_FIELD from "@salesforce/schema/Asset.ECSS_Floor_Number__c";
import UnitNumberOfBedrooms_FIELD from "@salesforce/schema/Asset.ECSS_Number_of_Bedrooms__c";
import UnitProjectName_FIELD from "@salesforce/schema/Asset.ECSS_Project__r.Name";
import UnitBuildingName_FIELD from "@salesforce/schema/Asset.ECSS_Building_Section__r.Name";

//Contact Fields
import ECSS_NewContactMobileNumber from "@salesforce/schema/Case.ECSS_NewContactMobileNumber__c";
import ECSS_NewContactCountryCode from "@salesforce/schema/Case.ECSS_NewContactCountryCode__c";
import NewContactEmail from "@salesforce/schema/Case.NewContactEmail__c";
import NewContactFirstName from "@salesforce/schema/Case.ECSS_NewContactFirstName__c";
import NewContactLastName from "@salesforce/schema/Case.ECSS_NewContactLastName__c";

import MobileNumber_FIELD from "@salesforce/schema/Case.MobileNumber__c";

import checkDuplicate from "@salesforce/apex/CaseService.checkDuplicate";

import TENANT_NAME from '@salesforce/schema/Account.Name';
//import COMPANY_VERTICALAcc from '@salesforce/schema/Account.Company_Vertical__c';
//import COMPANY_VERTICAL from "@salesforce/schema/Customer_Unit__c.Account__r.Company_Vertical__c";


export default class ECSS_CaseCreation extends NavigationMixin(
  LightningElement
) {
  //edit compionent variables
  @api accountSelectedRecordInput;
  @api preselectedRowIds;
  @api editCheck = false;
  @api compEditCheck = false;
  @api originEditCheck = false;
  @api typeEditCheck = false;
  @api subVerticalEditCheck = false;
  @api categoryEditCheck = false;
  @api subCategoryEditCheck = false;
  @api caseId = "";
  @api contractEditCheck = false;
  @api contractDetailEditCheck = false;
  @api preSelectedContractId = "";
  @api selectedContract;
  @api preSelectedContractDetailId = "";
  ////////Salutation vals ////////
  @track salutationOptions = [];
  @track salutationValue = "";
  @track mainContactUseage = false;
  ////////Country vals ////////
  @track countryOptions = [];
  @track countryValue = "";
  @track duplicateContact = false;
  ///////Nationality vals ///////
  @track nationalityOptions = [];
  @track nationalityValue = "";

  ////////////////
  //////////////////////
  @track contractCreationReq = false;
  @api customerTypeVal = "";
  @track salutatoinVal = "";
  @track isfcr = false;
  //track subcategory mapping
  catSubCatSubVerticalMap = new Map();
  catSubCatEltizamMap = new Map();
  catSubCatMap = new Map();
  companyWrapMap = new Map();
  @api isEmrgencyCase = false;
  @track isReplacement = false;
  @track isNewAdditionalCard = false;
  @track isReprogramming = false;
  @track PickListCaseRecordTypes = [];

  @track acceptedFormats = [".pdf", ".png", ".jpg", ".jpeg", ".docx", ".xlsx"];
  @track uploadedFiles = [];
  @track uploadDocIds = [];

  @track cAccountId;
  @track recordId; // This will receive the record ID as input
  @track record;
  @track error;
  @track unitId = "";
  @track customerId = "";
  @track caseRecordTypes = [];
  @track accountRecordTypes = [];
  @track wiredObjectInfo; // To hold the response from the wire
  @track subverticalPicklistResponse;
  @api subject = "";
  @track chosenCompanyName = "";
  @track chosenCompanyId = "";
  @api description = "";
  @track accountId = "";
  @track accountRec;
  @track unitFields = [];
  @track isMaintenance = false;
  @track selectedContractNoCalloutId = "";
  @api parentCaseId = "";
  @track contactSelectionDisabled = false;
  @track relatedAccContactDisabled = false;

  //Khidmah Contracts
  @track khidmahUnitContractsNoCallouts = [];
  @track khidmahUnitContracts = [];
  @track lengthKhidmahUnitContracts;
  @track lengthContractNoDetails;
  @track contractNoDetails;
  @track isKhidmah = false;
  @api selectedContractId;
  @track selectedProceedNoContract = "";
  @track skipDetailsSelection = false;
  @track contractDetails = [];
  @api selectedContractDetailId;
  @api preSelectedContracts = [];
  @api preSelectedContractDetails = [];
  @track preSelectedContractsTemp = [];
  @track preSelectedContractDetailsTemp = [];
  @track createNewContractRequest = false;
  @track contractStartDate = "";
  @track contractEndDate = "";
  @track selectedContractType;
  @track numberOfCallOuts = "";
  @track showContracts = true;
  @track customerTypeDropDownVisible = false;
  @track customerClaimedExistingContract = false;
  @track radioOptions = [
    {
      label: "One Time Service",
      value: "single"
    },
    {
      label: "Submit Contract for TopUp",
      value: "newContract"
    },
    {
      label: "Claimed Existing Contract",
      value: "existingContractClaim"
    }
  ];
  @track radioOptions2 = [
    {
      label: "One Time Service",
      value: "single"
    }
  ];
  @track contractColumns = [
    {
      label: "Contract",
      fieldName: "ContractNumber",
      hideDefaultActions: true
    },
    {
      label: "Start Date",
      fieldName: "StartDate",
      hideDefaultActions: true
    },
    {
      label: "End Date",
      fieldName: "EndDate",
      hideDefaultActions: true
    },
    {
      label: "Remaining Callouts",
      fieldName: "ECSS_Remaining_Call_Outs__c",
      hideDefaultActions: true
    },
    {
      label: "Contract Type",
      fieldName: "ECSS_ContractOrganizationType__c",
      hideDefaultActions: true
    }
  ];
  @track contractDetailsColumns = [
    {
      label: "Description",
      fieldName: "Description__c",
      hideDefaultActions: true
    },
    {
      label: "Service Material",
      fieldName: "Service_Material__c",
      hideDefaultActions: true
    },
    {
      label: "Item Details",
      fieldName: "ECSS_SAPLineExternalId__c",
      hideDefaultActions: true
    }
  ];
  @track pickCustomerType = [];
  ////////////////////

  // Category picklist values
  @track categoryPickListData;
  @track categorynoResults = false;
  @track categorySearchKey = "";
  @api categorySelectedValue = "";
  @track categoryDropdownVisible = false; // Dropdown visibility
  @track categoryPlaceholderText = "Search and select"; // Placeholder text
  @track caseCategoryOptions = [{}];
  @track stringifiedCaseCategoryOptions = JSON.stringify(
    this.caseCategoryOptions
  );
  @track categoryDisabled = true;

  //Non Existing Account Label
  @track AccountCreationLabel = "Request Account Creation";

  // SubCategory Picklist values
  @track isSubCategoryLoading = false;
  @track subCategoryPickListData;
  @track subCategorynoResults = false;
  @track subCategorySearchKey = "";
  @api subCategorySelectedValue = "";
  @track subCategoryDropdownVisible = false; // Dropdown visibility
  @track subCategoryPlaceholderText = "Search and select"; // Placeholder text
  @track subCaseCategoryOptions = [{}];
  @track subCaseCategoryDisabled = true;

  // CaseType Picklist values
  @track caseTypeNoResults = false;
  @track caseTypeSearchKey = "";
  @api caseTypeSelectedValue = "";
  @track caseTypeDropdownVisible = false; // Dropdown visibility
  @track caseTypePlaceholderText = "Search and select"; // Placeholder text
  @track caseTypeOptions = [{}];

  // SubVertical Picklist values
  @track subVerticalDataValue;
  @track subVerticalNoResults = false;
  @track subVerticalSearchKey = "";
  @api subVerticalSelectedValue = "";
  @track subVerticalDropdownVisible = false; // Dropdown visibility
  @track subVerticalPlaceholderText = "Search and select"; // Placeholder text
  @track subVerticalOptions = [{}];
  @track subVerticalDisabled = true;

  // ObjectCategory Picklist values
  @track objectCategoryPickListData;
  @track objectCategorynoResults = false;
  @track objectCategorySearchKey = "";
  @api objectCategorySelectedValue = "";
  @track objectCategoryDropdownVisible = false; // Dropdown visibility
  @track objectCategoryPlaceholderText = "Search and select"; // Placeholder text
  @track objectCaseCategoryOptions = [{}];
  @track objectCategoryRecTypeList = [];
  @api objCatPickListData = "";
  @track objectCategoryDisabled = true;

  // New properties for Case Origin
  @track caseOriginDropdownVisible = false; // Dropdown visibility for Case Origin
  @track caseOriginSearchKey = ""; // Search key for Case Origin
  @api caseOriginSelectedValue = ""; // Selected value for Case Origin
  @track caseOriginFilteredOptions = []; // Filtered options for Case Origin
  @track caseOriginPlaceholderText = "Search and select"; // Placeholder text for Case Origin
  @track caseOriginNoResults = false; // To show no results message
  @track caseOriginOptions = []; // Static options for Case Origin

  //Company fields
  @track isCompanyLoading = false;
  @api companyPickListData;
  @track companySearchKey = "";
  @api companySelectedValue = "";
  @track companyId = "";
  @track companyDisabled = true;
  @track companyDropdownVisible = false; // Dropdown visibility
  @track companyPlaceholderText = "Search and select"; // Placeholder text
  @track companyFilteredOptions = []; // Filtered options for Case Origin
  @track companyNoResults = false; // To show no results message
  @track companyOptions = [];

  @track loadingUnitSelection = true;

  //Mobile Country Code for Cases
  @track countryCodeOptions = [];

  @track isLoading = true;
  @track accHREF = "/lightning/r/Account/";
  @track unitHREF = "/lightning/r/Asset/";
  @track companyHREF = "/lightning/r/Account/";

  @track contrAccName;
  @track contrAccHREF = '/lightning/r/Account/';

  @track categoryFilteredOptions = this.caseCategoryOptions;
  @track subCategoryFilteredOptions = this.subCaseCategoryOptions;
  @track caseTypeFilteredOptions = this.caseTypeOptions; // Filtered options for case type
  @track accountTypeFilteredOptions = this.accountTypeOptions;
  @track subVerticalFilteredOptions = this.subVerticalOptions; // Filtered options for sub vertical

  // Units choice values
  @track customerUnits = [];
  @track UnitSelerror;
  @track searchTerm = "";
  @track currentPage = 1;
  @track pageSize = 10;
  @track unitsAvailable = false;
  @track columns = [
    {
      label: "Unit",
      fieldName: "unitNameUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "unitName" },
        target: "_blank"
      },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Unit Code",
      fieldName: "unitCode",
      hideDefaultActions: true,
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" }
    },
    {
      label: "Unit Type",
      fieldName: "unitType",
      hideDefaultActions: true,
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" }
    },
    {
      label: "Project",
      fieldName: "projectNameUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "projectNameAttr" },
        target: "_blank"
      },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Zone",
      fieldName: "zoneNameUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "zoneNameAttr" },
        target: "_blank"
      },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Building",
      fieldName: "buildingNameUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "buildingNameAttr" },
        target: "_blank"
      },
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Description",
      fieldName: "description",
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    },
    {
      label: "Companies",
      fieldName: "compoptions",
      wrapText: true, // Enables wrapping
      cellAttributes: { class: "wrap-text" },
      hideDefaultActions: true
    }

    /*{
        type: 'action',
        typeAttributes: { rowActions: actions },
        },*/
  ];

  @track flowApiName = "Test_ScreenFLow"; // Replace with your flow's API name
  @track selectedUnitId;
  @track selectedUnit;

  @track projectOptions = [];
  @track filteredProjects = [];
  @track selectedProject;

  @track buildingOptions = [];
  @track filteredBuildings = [];
  @track selectedBuilding;
  @track buildingValue = "0";
  @track zoneValue = "0";
  @track projectValue = "0";
  @track zoneOptions = [];
  @track filteredZones = [];
  @track selectedZone;
  @track isPerson = false;
  //End of unit selection

  // AccountType Picklist values
  @track accountTypeNoResults = false;
  @track accountTypeSearchKey = "";
  @track accountTypeSelectedValue = "";
  @track accountTypeSelectedLabel = "";
  @track accountTypeDropdownVisible = false; // Dropdown visibility
  @track accountTypePlaceholderText = "Search and select"; // Placeholder text
  @track accountIsPerson = false;
  @track accountIsComp = false;
  @track accountTypeOptions = [{}];
  @track typeValueMap = new Map();
  @track newAccContractExists = false;
  @track assetAccExists = false;
  // End of AccountType values

  // Contact Picklist values
  @track contactRelatedCmpValue = "";
  @track contactRelatedCmpValueId = "";
  @track contactNoResults = false;
  @track contactSearchKey = "";
  @track contactSelectedValue = "";
  @track contactSelectedLabel = "";
  @track contactDropdownVisible = false; // Dropdown visibility
  @track contactPlaceholderText = "Search and select"; // Placeholder text
  @track contactValueMap = new Map();
  @track contactoptions = [];
  @track contactFilteredOptions = [];
  @track contactId = "";
  @track contactName = "";
  @track contactSelectionPreview = false;
  //End of contact values

  // Case Account Values
  @track accName = "";
  @track accRegisNo = "";
  @track accPasspNo = "";
  @track accEmiratesId = "";
  @track accEmail = "";
  @track countryCode = "";
  @track mobilePhone = "";
  @track accFirstName = "";
  @track accMiddleName = "";
  @track accLastName = "";
  @track accFloor = "";
  @track accApartmentNumber = "";
  @track packageType = "";
  @track accApartmentNo = "";
  @track accPackageType = "";
  @track accContractNo = "";
  @track accStreetNo = "";
  @track accStreetName = "";
  @track accZipCode = "";
  @track duplicateAccount = false;

  //Account lookup values
  // Asset Picklist values
  @track assetNoResults = false;
  @track assetSearchKey = "";
  @api assetSelectedValue = "";
  @track assetDropdownVisible = false; // Dropdown visibility
  @track assetPlaceholderText = "Search and select"; // Placeholder text
  @track accAssetOptions = [];
  @track accAssetFilteredOptions = this.accAssetOptions;

  //Building Picklist values
  @track buildingNoResults = false;
  @track buildingSearchKey = "";
  @api buildingSelectedValue = "";
  @track buildingDropdownVisible = false; // Dropdown visibility
  @track buildingPlaceholderText = "Search and select"; // Placeholder text
  @track accbuildingOptions = [{}];
  @track accBuildingFilteredOptions = this.accbuildingOptions;

  @track accountCreationCheckbox = false;
  @track isKingsfield = false;

  // End of account creation values

  // Fields to retrieve
  @track fields = [
    ACCOUNT_LOOKUP,
    ASSET_LOOKUP,
    NAME_FIELD,
    ACCOUNT_NAME,
    ASSET_NAME,
    ASSET_bedroomNumber,
    ASSET_floorNumber,
    ASSET_linkedProject,
    ASSET_linkedBuilding
  ];
  @track unitFields = [
    UnitBuildingName_FIELD,
    UnitProjectName_FIELD,
    UnitNumberOfBedrooms_FIELD,
    UnitFloorNumbers_FIELD,
    UnitNAME_FIELD
  ];
  //newcontactcreationpoints
  @track contactCreationCheckbox = false;
  @track contactFirstName = "";
  @track contactLastName = "";
  @track contactEmail = "";
  @track contactCountryCode = "";
  @track contactMobileCountry = "";
  @track contactPhoneInvalid = false;

  @track tenantName;
  @track showTenant = false;
  @track tenantHREF = "/lightning/r/Account/";
  @track selectedType ="Functional Location";
  get typeOptions() {
    return [
        { label: 'Functional Location', value: 'Functional Location' },
        { label: 'Ecss Unit', value: 'Ecss Unit' }
    ];
}

// Handle dropdown change
handleTypeChange(event) {
    this.selectedType = event.detail.value;
    
}
  // Wire to capture the current page reference, and reset variables when it changes
  @wire(CurrentPageReference)
  pageRef;

  // Wire to get the current page reference
  @wire(CurrentPageReference)
  getCurrentPageReference(currentPageReference) {
    console.log("Current Page Reference:", currentPageReference);
    if (
      (currentPageReference && currentPageReference.state.c__recordId == "") ||
      (currentPageReference && currentPageReference.state.c__recordId == null)
    ) {
      this.isLoading = false;
    } else {
      if (currentPageReference && currentPageReference.state.c__recordId) {
        this.recordId = currentPageReference.state.c__recordId;
        console.log("Record ID from URL:", this.recordId);
        console.log('cAccountId : ', currentPageReference.state.c__accountId);
        this.isLoading = false; // Set loading false once recordId is retrieved
      } else {
        console.log("No recordId found in URL.");
        this.isLoading = false; // Set loading false once recordId is retrieved
      }
    }
    if (currentPageReference && currentPageReference.state.c__accountId) {
      this.cAccountId = currentPageReference && currentPageReference.state.c__accountId;
    }
  }

  @wire(getSalutationValues)
  wiredSalutations({ error, data }) {
    if (data) {
      this.salutationOptions = data.map((value) => ({
        label: value,
        value: value
      }));
    } else if (error) {
      console.error("Error fetching salutation values:", error);
    }
  }
  @wire(getCountryValues)
  wiredCountryValues({ error, data }) {
    if (data) {
      console.log("Data for country values:", data);
      this.countryOptions = data.map((value) => ({
        label: value,
        value: value
      }));
    } else if (error) {
      console.error("Error fetching salutation values:", error);
    }
  }
  @wire(getNationalityValues)
  wiredNationalities({ error, data }) {
    if (data) {
      this.nationalityOptions = data.map((value) => ({
        label: value,
        value: value
      }));
    } else if (error) {
      console.error("Error fetching nationality values:", error);
    }
  }

  @wire(categoryValues)
  categoryValues({ data, error }) {
    if (data) {
      // this.categories = data.categories;  // First list in output
      // this.ecssCategories = data.eCSSCategories;  // Second list in output
      // this.subCategories = data.subCategories;
      // this.ecssSubCategories = data.eCSSSubCategories;
      this.catSubCatMap = new Map(Object.entries(data.catSubCatMap));
      this.catSubCatEltizamMap = new Map(
        Object.entries(data.catSubCatEltizamMap)
      );
      this.catSubCatSubVerticalMap = new Map(
        Object.entries(data.catSubCatSubVerticalMap)
      );
    } else if (error) {
      this.showToast(
        "Error",
        "Error fetching categories: " + error.body.message,
        "error"
      );
    }
  }
  //to get related account on the asset if exists
  @wire(getRelatedAcc, {
    assetId: "$unitId"
  })
  wiredAccountRecord({ error, data }) {
    console.log("in the getRelatedAcc wire");
    if (this.accountId == "" || this.accountId == null) {
      if (data) {
        this.assetAccExists = true;
        this.isPerson = false;
        console.log("In the data of the get related acc method: ");
        this.accountId = data.accountId;
        this.cAccountId = data.accountId;
        this.accountRec = data.accountRec;
        this.accHREF += data.accountId;
        this.accHREF += "/view";
        this.AccountCreationLabel = "Request Account Creation";
        this.accountSelectedRecordInput = data.accountRec;
        console.log("AccRFec:" + this.accountRec);
        this.handleContactFetch();
        this.customerClaimedExistingContract = false;
        this.accountCreationCheckbox = false;
        this.accName = "";
        this.accRegisNo = "";
        this.accEmiratesId = "";
        this.accPasspNo = "";
        this.accEmail = "";
        this.countryCode = "";
        this.mobilePhone = "";
        this.accZipCod = "";
        this.accStreetName = "";
        this.accStreetNo = "";
        this.accApartmentNo = "";
        this.buildingSelectedValue = "";
        this.accFirstName = "";
        this.accMiddleName = "";
        this.accLastName = "";
        this.accFloor = "";
        this.assetSelectedValue = "";
        this.accPackageType = "";
        this.showToast(
          "warning",
          "There is a customer linked to this this unit, which means this account exists on the system",
          "warning"
        );
      }
    }
  }


  @wire(getRecord, {
    recordId: "$recordId",
    fields: "$fields"
  })
  wiredRecord({ error, data }) {
    if (this.recordId) {
      // Ensure recordId is valid before processing
      console.log("In the getRecord method2");
      if (data) {
        this.record = data;
        this.accountId = data.fields.Account__c.value;
        this.accHREF += data.fields.Account__c.value;
        this.accHREF += "/view";
        this.unitId = data.fields.Unit__c.value;
        this.unitHREF += data.fields.Unit__c.value;
        this.unitHREF += "/view";
        this.isLoading = false; // Data is loaded, hide loading
        this.handleContactFetch();
        //const companyVertical = data.fields.Account__r?.value?.fields?.Company_Vertical__c?.value || '';

        // Check for "kingsfield" 
        //if (companyVertical.toLowerCase().includes('kingsfield')) {
       //   this.isKingsfield = true;
       // } else {
        //  this.isKingsfield = false;
      //  }
      } else if (error) {
        this.error = error;
        this.record = undefined;
        this.isLoading = false; // Hide loading on error
        console.error("Error:", JSON.stringify(error)); // Log error
      }
    }
  }
  // Wire to get the record data
  @wire(getRecord, { recordId: "$cAccountId", fields: [TENANT_NAME] })
  wiredAccount({ error, data }) {
   /* if(data){
      const companyVertical =data.fields.Company_Vertical__c?.value || '';
        // Check for "kingsfield" 
        if (companyVertical.toLowerCase().includes('kingsfield')) {
          this.isKingsfield = true;
        } else {
          this.isKingsfield = false;
        }
    }*/
    if (this.cAccountId) {
      this.showTenant = false;
      console.log('In the cAccount');
      if (data) {
        console.log('Entered here');
        if (this.cAccountId != this.accountId) {
          console.log('this.accountId : ' + this.accountId);
          console.log('this,caccountId : ' + this.cAccountId);
          this.tenantName = data.fields.Name.value;
          this.showTenant = true;
          this.tenantHREF += this.cAccountId;
          this.tenantHREF += "/view";
        }
        else {
          this.showTenant = false;
        }

      }
      else if (error) {
        this.error = error;
        this.tenantName = undefined;
        this.isLoading = false; // Hide loading on error
        console.error("Error:", JSON.stringify(error)); // Log error
      }
    }
  }
  // Fetch picklist values based on selected record type
  @wire(getPicklistValuesByRecordType, {
    objectApiName: case_OBJECT,
    recordTypeId: "$caseTypeSelectedValue"
  })
  picklistValuesCaseType({ data, error }) {
    console.log("in the casetype");
    this.isCompanyLoading = true;
    if (data) {
      const customerTypesField = data.picklistFieldValues.CustomerType__c;
      if (customerTypesField) {
        this.pickCustomerType = customerTypesField.values.map((value) => ({
          label: value.label, // Assign the label
          value: value.value // Assign the value
        }));
      }
    }
    if (data && this.caseTypeSelectedValue) {
      console.log("in the wire", JSON.stringify(data));
      const objCatPicklistField =
        data.picklistFieldValues.ECSS_Object_Category__c; // Replace with your actual field
      console.log("in the objcat", JSON.stringify(data));
      this.objCatPickListData = objCatPicklistField;
      if (objCatPicklistField) {
        this.objectCategoryRecTypeList = objCatPicklistField.values.map(
          (value) => value.value
        );
      }

      const compPicklistField = data.picklistFieldValues.ECSS_CompanyOptions__c; // Replace with your actual field
      console.log("in the subvertical", JSON.stringify(data));
      this.companyPickListData = compPicklistField;
      if (compPicklistField) {
        console.log("in the comp");
        this.companyOptions = compPicklistField.values.map((value) => ({
          label: value.label,
          value: value.value
        }));
        this.companyFilteredOptions = this.companyOptions;
        this.isCompanyLoading = false;
      }
      const picklistField = data.picklistFieldValues.SubVertical__c; // Replace with your actual field
      console.log("in the subvertical", JSON.stringify(data));
      this.subVerticalDataValue = picklistField;
      if (picklistField) {
        this.subVerticalOptions = picklistField.values.map((value) => ({
          label: value.label,
          value: value.value
        }));

        this.subVerticalFilteredOptions = this.subVerticalOptions; // Set filtered options
        if (this.subVerticalFilteredOptions.length == 1) {
          this.subVerticalDisabled = false;
          this.categoryDisabled = false;
          this.objectCategoryDisabled = false;
          this.subCaseCategoryDisabled = false;
          this.subVerticalSearchKey = this.subVerticalFilteredOptions[0].label;
          this.subVerticalSelectedValue =
            this.subVerticalFilteredOptions[0].value;
          this.subVerticalPlaceholderText =
            this.subVerticalFilteredOptions[0].label;
        }
        //category handling
        const categpryPicklistField = data.picklistFieldValues.CaseCategory__c; // Replace with your actual field
        console.log("in the wire", JSON.stringify(categpryPicklistField));
        this.categoryPickListData = categpryPicklistField;

        if (categpryPicklistField) {
          this.caseCategoryOptions = categpryPicklistField.values.map(
            (value) => ({
              label: value.label,
              value: value.value
            })
          );
          this.stringifiedCaseCategoryOptions = JSON.stringify(
            this.caseCategoryOptions
          );
          this.categoryFilteredOptions = this.caseCategoryOptions; // Set filtered options
          if (this.categoryFilteredOptions.length == 1) {
            this.categoryDisabled = false;
            this.objectCategoryDisabled = false;
            this.subCaseCategoryDisabled = false;
            this.categorySearchKey = this.categoryFilteredOptions[0].label;
            this.categorySelectedValue = this.categoryFilteredOptions[0].value;
            console.log(
              "caseCateogrySelectedValeu" + this.categorySelectedValue
            );
            this.categoryPlaceholderText = this.categorySearchKey;
          }
        }
        //sub_category handling
        /*  const subCategpryPicklistField = data.picklistFieldValues.ECSS_Sub_Category__c; // Replace with your actual field
                  this.subCategoryPickListData = subCategpryPicklistField;
                  if (subCategpryPicklistField) {
                      this.subCaseCategoryOptions = subCategpryPicklistField.values.map(value => ({
                          label: value.label,
                          value: value.value
                      }));
  
                      this.subCategoryFilteredOptions = this.subCaseCategoryOptions; // Set filtered options
  
              
  
  
                  }  */
        console.log("Reached subcategory");
        //origin handling
        const originPicklistField = data.picklistFieldValues.Origin; // Replace with your actual field
        if (originPicklistField) {
          this.caseOriginOptions = originPicklistField.values.map((value) => ({
            label: value.label,
            value: value.value
          }));

          this.caseOriginFilteredOptions = this.caseOriginOptions; // Set filtered options
          //In case of editting to preview pre-existing values//
          if (this.caseOriginSelectedValue && this.originEditCheck) {
            this.originEditCheck = false;
            this.caseOriginSearchKey = this.caseOriginOptions.find(
              (option) => option.value === this.caseOriginSelectedValue
            ).label;
            this.caseOriginPlaceholderText = this.caseOriginSearchKey; // Show the selected option as placeholder text
          }
          //End of Editting//
        }
        console.log("Reached origin");

        /////******In case of editting to preview pre-existing values*****///////

        if (this.subVerticalSelectedValue && this.subVerticalEditCheck) {
          this.subVerticalEditCheck = false;

          this.subVerticalSearchKey = this.subVerticalOptions.find(
            (option) => option.value === this.subVerticalSelectedValue
          ).label;
          this.subVerticalPlaceholderText = this.subVerticalSearchKey;
          this.subVerticalDisabled = false; // Show the selected option as placeholder text
          //clear the selected value for category

          let keyComp =
            this.subVerticalDataValue.controllerValues[
            this.companySelectedValue
            ];

          this.subVerticalFilteredOptions =
            this.subVerticalDataValue.values.filter((opt) =>
              opt.validFor.includes(keyComp)
            );
          // Now filter category options based on the selected subvertical
          let key =
            this.categoryPickListData.controllerValues[
            this.subVerticalSelectedValue
            ];
          this.categoryFilteredOptions =
            this.categoryPickListData.values.filter((opt) =>
              opt.validFor.includes(key)
            );
          this.companyDisabled = false;
          this.companySearchKey = this.companyOptions.find(
            (option) => option.value === this.companySelectedValue
          ).label;
          // this.companyFilteredOptions = [];
          this.companyPlaceholderText = this.categorySearchKey; // Show the selected option as placeholder text
        }
        //******************End of Editting****************//
        /////******In case of editting to preview pre-existing values*****///////
        console.log("categorySelectedValue" + this.categorySelectedValue);
        if (this.categorySelectedValue && this.categoryEditCheck) {
          console.log("caseCateogrySelectedValeu" + this.categorySelectedValue);
          this.categoryEditCheck = false;
          this.categorySearchKey = this.caseCategoryOptions.find(
            (option) => option.value === this.categorySelectedValue
          ).label;
          console.log("caseCateogrySelectedValeu" + this.categorySelectedValue);
          this.categoryPlaceholderText = this.categorySearchKey; // Show the selected option as placeholder text
          this.categoryDisabled = false;
          // Now filter category options based on the selected subcategory
          let key =
            this.subCategoryPickListData.controllerValues[
            this.categorySelectedValue
            ];
          this.subCategoryFilteredOptions =
            this.subCategoryPickListData.values.filter((opt) =>
              opt.validFor.includes(key)
            );
        }
        //******************End of Editting****************//
        /////******In case of editting to preview pre-existing values*****///////
        const selectedOption = this.objectCaseCategoryOptions.find(
          (option) => option.value === this.objectCategorySelectedValue
        );
        if (selectedOption) {
          this.objectCategorySearchKey = selectedOption.label; // Update search key to display label
          this.objectCategoryPlaceholderText = selectedOption.label; // Set placeholder
        }
        if (this.subCategorySelectedValue && this.subCategoryEditCheck) {
          this.subCategoryEditCheck = false;
          this.subCaseCategoryDisabled = false;
          this.subCategorySearchKey = this.subCaseCategoryOptions.find(
            (option) => option.value === this.subCategorySelectedValue
          ).label;
          this.subCategoryPlaceholderText = this.subCategorySearchKey; // Show the selected option as placeholder text
          try {
            refreshApex(this.wiredObjectInfo);
          } catch (error) {
            console.log(error);
          }
        }

        //******************End of Editting****************//

        //Contract Type Handling
        this.pickKhidmahContractTypes =
          data.picklistFieldValues.ECSS_Khidmah_Contract_Type__c.values;
      }
      this.pickKhidmahContractTypes =
        data.picklistFieldValues.ECSS_Khidmah_Contract_Type__c.values;

      console.log(this.subVerticalSelectedValue);
    } else if (error) {
      console.error("Error retrieving picklist values: ", error);
    }
  }
  @wire(getKhidmahContracts, {
    ecssUnitId: "$unitId",
    accountId: "$accountId",
    caseCategory: "$categorySelectedValue",
    compName: "$companySelectedValue",
    subVertical: "$subVerticalSelectedValue"
  })
  wiredKhidmahContracts({ error, data }) {
    this.newAccContractExists = false;
    if (data) {
      console.log("In Contracts Wire");
      this.selectedContractId = "";
      this.preSelectedContracts = [];
      this.preSelectedContractDetails = [];
      this.preSelectedContractDetailsTemp = [];
      this.preSelectedContractsTemp = [];
      this.contractDetails = [];
      console.log("activeWithRemaining:" + data.activeContractsWithRemaining);
      this.khidmahUnitContracts = data.activeContractsWithRemaining;
      this.khidmahUnitContractsNoCallouts = data.activeContractsWORemaining;
      this.lengthKhidmahUnitContracts =
        data.activeContractsWithRemaining.length > 0;
      if (this.lengthKhidmahUnitContracts > 0) {
        console.log("length>0");
        let tmp = data.activeContractsWithRemaining;
        console.log("after tmp");
        let hasZeroCallOuts = true;

        for (let item of tmp) {
          if (item.ECSS_Remaining_Call_Outs__c > 0) {
            hasZeroCallOuts = false;
            break; // Optional: break early if you only care about the first match
          }
        }

        if (hasZeroCallOuts) {
          console.log("entered in the remaining call out");
          this.contractColumns = [
            {
              label: "Contract",
              fieldName: "ContractNumber",
              hideDefaultActions: true
            },
            {
              label: "Start Date",
              fieldName: "StartDate",
              hideDefaultActions: true
            },
            {
              label: "End Date",
              fieldName: "EndDate",
              hideDefaultActions: true
            },
            {
              label: "Contract Type",
              fieldName: "ECSS_ContractOrganizationType__c",
              hideDefaultActions: true
            }
          ];
        }


      }
      this.lengthContractNoDetails =
        data.activeContractsNoDetails.length > 0 &&
        !this.lengthKhidmahUnitContracts;

      if (this.khidmahUnitContractsNoCallouts.length == 0) {
        this.radioOptions = [
          {
            label: "One Time Service",
            value: "single"
          },
          {
            label: "Claimed Existing Contract",
            value: "existingContractClaim"
          }
        ];
      } else {
        this.radioOptions = [
          {
            label: "One Time Service",
            value: "single"
          },
          {
            label: "Submit Contract for TopUp",
            value: "newContract"
          },
          {
            label: "Claimed Existing Contract",
            value: "existingContractClaim"
          }
        ];
      }
      if (this.lengthContractNoDetails) {
        this.khidmahUnitContracts = data.activeContractsNoDetails;

        //if (data.activeContractsNoDetails.length == 1) {
        const preSelect = [];
        preSelect.push(data.activeContractsNoDetails[0].Id);
        //console.log('DATATABLE',data[0].Id);
        this.preSelectedContractsTemp = preSelect;
        this.preSelectedContracts = preSelect;
        this.selectedContract = data.activeContractsNoDetails[0];
        console.log("this.selectedContract: " + this.selectedContract);
        this.selectedContractId = data.activeContractsNoDetails[0].Id;
        // }
        this.selectedProceedNoContract = "One Time Service";
      }
      console.log(
        "this.lengthKhidmahUnitContracts:" + this.lengthKhidmahUnitContracts
      );
      // Check if new Customer Creation
      if (this.accountCreationCheckbox && this.lengthKhidmahUnitContracts) {
        // active contracts exists
        this.newAccContractExists = true;
        this.handleContactFetch();
      } else {
        this.newAccContractExists = false;
      }
      if (!this.contractCreationReq && !this.accountCreationCheckbox)
        this.showContracts = true;
      if (data.activeContractsWithRemaining.length === 1) {
        console.log("in the data.activeContractsWithRemaining.length");
        const preSelect = [];
        preSelect.push(data.activeContractsWithRemaining[0].Id);
        //console.log('DATATABLE',data[0].Id);
        this.preSelectedContractsTemp = preSelect;
        this.preSelectedContracts = preSelect;
        this.selectedContract = data.activeContractsWithRemaining[0];
        console.log("this.selectedContract: " + this.selectedContract);
        this.selectedContractId = data.activeContractsWithRemaining[0].Id;
        if (data.activeContractsWithRemaining[0].Unit_Contracts__r) {
          this.contractDetails =
            data.activeContractsWithRemaining[0].Unit_Contracts__r;
          if (this.contractDetails.length >= 1) {
            const preSelectDetail = [];
            preSelectDetail.push(this.contractDetails[0].Id);
            this.preSelectedContractDetails = preSelectDetail;
            this.preSelectedContractDetailsTemp = preSelectDetail;
            this.selectedContractDetailId = this.contractDetails[0].Id;
          }
        }
      } else {
        if (!this.accountCreationCheckbox) this.showContracts = true;
        if (this.contractEditCheck && this.preSelectedContractId != "") {
          this.contractEditCheck = false;
          const preSelectEdit = [];
          preSelectEdit.push(this.preSelectedContractId);
          this.preSelectedContracts = preSelectEdit;
          this.selectedContractId = this.preSelectedContractId;
          if (
            this.contractDetailEditCheck &&
            this.preSelectedContractDetailId != ""
          ) {
            const preSelectDetailEdit = [];
            preSelectDetailEdit.push(this.contractDetailEditCheck);
            this.preSelectedContractDetails = preSelectDetailEdit;
            this.selectedContractDetailId = this.contractDetailEditCheck;
            this.contractDetailEditCheck = false;
          }
        }
      }
      if (this.chosenCompanyName.includes("Khidmah")) {
        this.isKhidmah = true;
      } else {
        this.isKhidmah = false;
      }
    } else if (error) {
      console.error(error);
    }
  }

  // Fetch Account picklist values based on selected record type
  @wire(getPicklistValuesByRecordType, {
    objectApiName: account_OBJECT,
    recordTypeId: "$accountTypeSelectedValue"
  })
  picklistValuesAccountType({ data, error }) {
    if (data) {
      console.log("in the wire", JSON.stringify(data));
      if (this.accountTypeSelectedLabel.includes("Person"))
        var picklistField = data.picklistFieldValues.MobileCountryCode__pc; // Replace with your actual field
      else picklistField = data.picklistFieldValues.MobileCountryCode__c;
      console.log("in the countrycode", JSON.stringify(picklistField));
      this.countryCodeOptions = data.values;
      if (picklistField) {
        this.countryCodeOptions = picklistField.values.map((value) => ({
          label: value.label,
          value: value.value
        }));
      }
      console.log(this.countryCodeOptions);
    } else if (error) {
      console.error("Error retrieving picklist values: ", error);
    }
  }
  //Inv Values
  @wire(getInvValues, {})
  wiredInvData({ error, data }) {
    if (data) {
      let buildingVals = data.buildingVals;
      let zoneVals = data.zoneVals;
      let projectVals = data.projectVals;
      console.log("in the invVals");
      projectVals.forEach((item) => {
        // console.log('index'+this.projectOptions.some(option => option.value === item.projectId));
        if (
          item.value &&
          !this.projectOptions.some((option) => option.value === item.value)
        ) {
          this.projectOptions.push({
            label: item.label,
            value: item.value
          });
        }
      });
      this.filteredProjects = this.projectOptions;

      buildingVals.forEach((item) => {
        // Push into buildingOptions if buildingId is available and not already added
        if (
          item.value &&
          !this.buildingOptions.some((option) => option.value === item.value)
        ) {
          console.log("in the if:+" + item.label);
          this.buildingOptions.push({
            label: item.label,
            value: item.value,
            projectId: item.projectId,
            zoneId: item.zoneId
          });
        }
      });
      this.filteredBuildings = this.buildingOptions;
      zoneVals.forEach((item) => {
        if (
          item.value &&
          !this.zoneOptions.some((option) => option.value === item.value)
        ) {
          this.zoneOptions.push({ label: item.label, value: item.value, projectId: item.projectId, });
        }
      });
      this.filteredZones = this.zoneOptions;
    }
  }
  //Unit selection values
  @wire(getCustomerUnits, {
    accountId: "$accountId",
    searchTerm: "$searchTerm",
    assetSearchKey: "$assetSearchKey",
    buildingValue: "$buildingValue",
    projectValue: "$projectValue",
    zoneValue: "$zoneValue",
    UCCrecordtypeName:"$selectedType"
  })
  wiredCustomerUnits({ error, data }) {
    console.log("In the customerUnit Wire");
    if (!this.record && data) {
      this.loadingUnitSelection = false;
      let unitNameUrl;
      let projectNameUrl;
      let buildingNameUrl;
      let zoneNameUrl;
      let projectNameAttr;
      let buildingNameAttr;
      let zoneNameAttr;
      this.accAssetOptions = [];
      this.customerUnits = data.map((row) => {
        unitNameUrl = `/${row.unitId}`;
        projectNameUrl = row.projectId ? `/${row.projectId}` : "";
        projectNameAttr = row.projectId ? row.projectName : "";
        buildingNameUrl = row.buildingId ? `/${row.buildingId}` : "";
        buildingNameAttr = row.buildingId ? row.buildingName : "";
        zoneNameUrl = row.zoneId ? `/${row.zoneId}` : "";
        zoneNameAttr = row.zoneId ? row.zoneName : "";
        //projectClass =  row.projectId? 'slds-text-color_default' : 'slds-hide'
        return {
          ...row,
          unitNameUrl,
          projectNameUrl,
          projectNameAttr,
          buildingNameUrl,
          buildingNameAttr,
          zoneNameUrl,
          zoneNameAttr
        };
      });
      //console.log('zz');
      //this.projectOptions.push({ label: '', value: '' });
      ///////nowww////
      /*  data.forEach((item) => {
        // console.log('index'+this.projectOptions.some(option => option.value === item.projectId));
        if (
          item.projectId &&
          !this.projectOptions.some((option) => option.value === item.projectId)
        ) {
          this.projectOptions.push({
            label: item.projectName,
            value: item.projectId
          });
        }
      });
*/
      // Using map and single iteration to populate both accAssetOptions and buildingOptions
      data.map((item) => {
        // Push into accAssetOptions if unitName is not empty
        if (item.unitName !== "") {
          this.accAssetOptions.push({
            label: item.unitName,
            value: item.unitId,
            buildingIdval: item.buildingId,
            unitCode: item.unitCode
          });
        }
        console.log("in the building filling" + item.buildingId);
        // Push into buildingOptions if buildingId is available and not already added
        /////Nowwww/////
        /*  if (
          item.buildingId &&
          !this.buildingOptions.some(
            (option) => option.value === item.buildingId
          )
        ) {
          console.log("in the if:+" + item.buildingName);
          this.buildingOptions.push({
            label: item.buildingName,
            value: item.buildingId
          });
        } */
      });

      //this.zoneOptions.push({ label: '', value: '' });
      //////Nowwwww///
      /* data.forEach((item) => {
        if (
          item.zoneId &&
          !this.zoneOptions.some((option) => option.value === item.zoneId)
        ) {
          this.zoneOptions.push({ label: item.zoneName, value: item.zoneId });
        }
      });*/
      console.log("this.buildingOptions:" + this.buildingOptions);
      this.accbuildingOptions = this.buildingOptions;
      this.accBuildingFilteredOptions = this.buildingOptions;
      this.accAssetFilteredOptions = this.accAssetOptions;

      this.error = undefined;
      //console.log(this.customerUnits.length);
      // if (this.customerUnits.length === 0) {
      //   this.unitsAvailable = false;
      //  } else {
      this.unitsAvailable = true;
      //  }
      console.log("UnitsAvail" + this.unitsAvailable);
    } else if (error) {
      this.UnitSelerror = error;
      this.customerUnits = [];
      this.unitsAvailable = false;
    }
  }
  //CategoryHandling
  @wire(categoryReturnValues, {
    chosenType: "$caseTypeSearchKey",
    objectCategory: "$objectCategorySelectedValue",
    SubVertical: "$subVerticalSearchKey",
    subCategory: "$subCategorySelectedValue",
    categoryOpstionsLst: "$stringifiedCaseCategoryOptions"
  })
  categoryReturnValues({ error, data }) {
    console.log("in the catg wiree now" + this.stringifiedCaseCategoryOptions);
    if (data) {
      if (
        data != null &&
        data != "undefined" &&
        data.length > 0 &&
        this.categorySelectedValue == ""
      ) {
        console.log("in the  category wire", this.objectCategorySelectedValue);
        console.log("CategoryData" + JSON.stringify(data));
        this.categoryFilteredOptions = [];
        this.categoryFilteredOptions = data
          .filter((conta) => conta && conta.valName) // Filter out falsy items and items without `valName`
          .map((conta) => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
        this.caseCategoryOptions = this.categoryFilteredOptions;
        this.stringifiedCaseCategoryOptions = JSON.stringify(
          this.caseCategoryOptions
        );
        if (this.categoryFilteredOptions.length == 1) {
          this.categoryDisabled = false;
          this.objectCategoryDisabled = false;
          this.subCaseCategoryDisabled = false;
          console.log("Category Value --> " + data[0].valName);
          this.categorySearchKey = data[0].valName;
          this.categorySelectedValue = data[0].valName;
          console.log("categorySelectedValue" + this.categorySelectedValue);
          this.categoryPlaceholderText = data[0].valName; // Show the selected option as placeholder text*/
        }
      }
    } else if (error) {
      this.showToast(
        "Error",
        "Error fetching categories: " + error.body.message,
        "error"
      );
    }
  }
  //ObjectCategoryHandling
  @wire(objectCategoryValues, {
    chosenType: "$caseTypeSearchKey",
    Category: "$categorySelectedValue",
    SubVertical: "$subVerticalSelectedValue",
    subCategory: "$subCategorySelectedValue"
  })
  objectCategoryValues({ error, data }) {
    if (data && data != null && data != "undefined" && data.length > 0) {
      console.log("in the object category wire");
      this.objectCategoryFilteredOptions = [];
      console.log(
        "this.objectCategoryRecTypeList:" +
        JSON.stringify(this.objectCategoryRecTypeList)
      );
      if (this.objectCategoryRecTypeList) {
        console.log("in the objctCategoryList" + JSON.stringify(data));
        this.objectCategoryFilteredOptions = data
          .filter(
            (conta) =>
              conta &&
              conta.valName &&
              this.objectCategoryRecTypeList.includes(conta.valName)
          )
          .map((conta) => ({ label: conta.labelName, value: conta.valName }));
      }
      /* this.objectCategoryFilteredOptions = data
             .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
             .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format*/
      this.objectCaseCategoryOptions = this.objectCategoryFilteredOptions;
      if (this.editCheck && this.objectCategorySelectedValue) {
        this.objectCategoryDisabled = false;
        const selectedOption = this.objectCaseCategoryOptions.find(
          (option) => option.value === this.objectCategorySelectedValue
        );
        if (selectedOption) {
          this.objectCategorySearchKey = selectedOption.label; // Update search key to display label
          this.objectCategoryPlaceholderText = selectedOption.label; // Set placeholder
        }
      }
      if (
        this.objectCategoryFilteredOptions.length == 1 &&
        this.objectCategorySelectedValue == ""
      ) {
        console.log("ObjectCategory Value --> " + data[0].valName);
        this.objectCategorySearchKey = data[0].labelName;

        this.objectCategorySelectedValue = data[0].valName;
        console.log(
          "caseCateogrySelectedValeu" + this.subCategorySelectedValue
        );
        // this.subCategoryPlaceholderText = data[0].valName; // Show the selected option as placeholder text*/
      }
    } else if (error) {
      this.showToast(
        "Error",
        "Error fetching categories: " + error.body.message,
        "error"
      );
    }
  }
  //SubcategoryHandling
  @wire(subCategoryValues, {
    Category: "$categorySelectedValue",
    SubVertical: "$subVerticalSelectedValue",
    chosenType: "$caseTypeSearchKey",
    ObjectCateogry: "$objectCategorySelectedValue"
  })
  subCategoryValues({ error, data }) {
    this.isSubCategoryLoading = true;
    console.log("SubCategoryWireBf");
    if (data && data != null && data != "undefined" && data.length > 0) {
      console.log("Raw Data from Wire:", JSON.stringify(data));

      console.log("SubCategoryWire");
      this.subCategoryFilteredOptions = [];
      this.subCategoryFilteredOptions = data
        .filter((conta) => conta && conta.valName) // Filter out falsy items and items without `valName`
        .map((conta) => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
      this.subCaseCategoryOptions = this.subCategoryFilteredOptions; // Map directly to the desired format
      if (this.editCheck && this.subCategoryEditCheck) {
        this.subCategoryEditCheck = false;
        this.subCaseCategoryDisabled = false;
        this.subCategorySearchKey = this.subCaseCategoryOptions.find(
          (option) => option.value === this.subCategorySelectedValue
        ).label;
        this.subCategoryPlaceholderText = this.subCategorySearchKey; // Show the selected option as placeholder text
      }
      if (
        this.subCategoryFilteredOptions.length == 1 &&
        this.subCategorySelectedValue == ""
      ) {
        console.log("SubCategory value -->" + data[0].valName);
        this.subCategorySelectedValue = data[0].valName;
        this.subCategorySelectedValue = data[0].valName;
        this.subcategoryPlaceholderText = data[0].valName;
      }
      this.isSubCategoryLoading = false;
    } else if (error) {
      this.showToast(
        "Error",
        "Error fetching categories: " + error.body.message,
        "error"
      );
    }
  }
  @wire(getRecord, {
    recordId: "$unitId",
    fields: "$unitFields"
  })
  UnitwiredRecord({ error, data }) {
    if (this.unitId) {
      // Ensure recordId is valid before processing
      console.log("In the getRecord method");
      if (data) {
        this.selectedUnit = data;
      } else if (error) {
        this.UnitSelerror = error;
      }
    }
  }
  @wire(contactDuplicateRetrieval, {
    mobilePhone: "$contactMobileCountry",
    firstName: "$contactFirstName",
    lastName: "$contactLastName",
    isPerson: "$isPerson",
    accountId: "$accountId",
    email: "$contactEmail"
  })
  contactDuplicateExtract({ error, data }) {

    console.log('Incontact data retrieval : ', data);
    if (data) {
      this.contactCreationCheckbox = false;
      console.log('in here : ', data.Id);
      this.contactRelatedCmpValue = data;
      this.contactRelatedCmpValueId = data.Id;
      this.contactId = data.Id;
      this.contactMobileCountry = '';
      this.contactFirstName = '';
      this.contactLastName = '';
      this.contactEmail = '';

      console.log("this.contactRelatedCmpValue:" + this.contactRelatedCmpValue);
      if (this.contactRelatedCmpValue) {
        this.contactSelectionDisabled = true;
      } else {
        this.contactSelectionDisabled = false;
      }

    }
  }

  get totalPages() {
    return Math.ceil(this.filteredUnits.length / this.pageSize);
  }

  get isFirstPage() {
    return this.currentPage === 1;
  }

  get isLastPage() {
    return this.currentPage === this.totalPages;
  }

  get filteredUnits() {
    let searchPattern = this.searchTerm.trim();

    console.log("SEARCHPATT" + searchPattern);

    console.log("SEARCH" + this.searchTerm);
    if (
      !this.selectedProject &&
      !this.selectedZone &&
      !this.selectedBuilding &&
      this.searchTerm === ""
    ) {
      return this.customerUnits;
    } else {
      return this.customerUnits.filter((customerUnit) => {
        const matchesProject = this.selectedProject
          ? customerUnit.projectId === this.selectedProject
          : false;
        const matchesZone = this.selectedZone
          ? customerUnit.zoneId === this.selectedZone
          : false;
        const matchesBuilding = this.selectedBuilding
          ? customerUnit.buildingId === this.selectedBuilding
          : false;
        //const matchesUnitName = this.searchTerm!=''?  customerUnit.unitName.toLowerCase().includes(this.searchTerm.toLowerCase()):false;
        let matchesUnitName = false;
        let matchesUnitCode = false;
        // console.log('customerUnit.unitCode:' + customerUnit.unitCode);
        if (searchPattern !== "") {
          // Handle the wildcard behavior: replace '*' with '.*'
          const regexPattern = searchPattern.replace(/\*/g, ".*").toLowerCase(); // Convert all '*' to regex match
          const regex = new RegExp(regexPattern);
          if (customerUnit.unitCode != null && customerUnit.unitCode != "")
            matchesUnitCode = regex.test(customerUnit.unitCode.toLowerCase());
          matchesUnitName = regex.test(customerUnit.unitName.toLowerCase());
        }
        //console.log(matchesUnitName);
        return (
          matchesProject ||
          matchesZone ||
          matchesBuilding ||
          matchesUnitName ||
          matchesUnitCode
        );
      });
    }

    //return this.filteredCustUnits;
    // return this.customerUnits.filter(customerUnit => customerUnit.unitName.toLowerCase().includes(this.searchTerm.toLowerCase()));
    //return this.customerUnits.filter(customerUnit =>customerUnit.projectId === this.selectedProject);
  }
  handleGetAccount() {
    console.log("getAccRecord:");
    getAccRecord({ contractVal: this.selectedContract }).then((result) => {
      console.log("in the then:" + result);
      console.log("resultname: " + result.Id);
      var recid = result[0].Id;
      this.accountSelectedRecordInput = result.find(
        (data) => data.Id === recid
      );
      if (this.accountSelectedRecordInput) {
        this.accountId = this.accountSelectedRecordInput.Id;
        this.accountRec = this.accountSelectedRecordInput;
        this.accHREF += this.accountSelectedRecordInput.Id;
        this.accHREF += "/view";
        this.handleContactFetch();
      }
    });
  }

  handleSearch(event) {
    this.searchTerm = event.target.value;
    this.assetSearchKey = "";
    this.currentPage = 1;
  }
  handleProjectChange(event) {
    this.selectedProject = event.detail.value;
    this.projectValue = event.detail.value;
    this.currentPage = 1;
    this.filteredBuildings = this.buildingOptions.filter((option) => option.projectId === this.selectedProject);
    this.filteredZones = this.zoneOptions.filter((option) => option.projectId === this.selectedProject);
    //console.log(this.selectedProject);
  }
  handleBuildingChange(event) {
    this.selectedBuilding = event.detail.value;
    this.buildingValue = event.detail.value;
    this.currentPage = 1;
    this.filteredProjects = this.projectOptions.filter((x) => x.value === (this.buildingOptions.find((b) => b.value === this.selectedBuilding).projectId));
    this.filteredZones = this.zoneOptions.filter((x) => x.value === (this.buildingOptions.find((b) => b.value === this.selectedBuilding).zoneId));
  }
  handleZoneChange(event) {
    this.zoneValue = event.detail.value;
    this.selectedZone = event.detail.value;
    this.currentPage = 1;
    this.filteredBuildings = this.buildingOptions.filter((option) => option.zoneId === this.selectedZone);
    this.filteredProjects = this.projectOptions.filter((x) => x.value === (this.zoneOptions.find((b) => b.value === this.selectedZone).projectId));

  }
  clearProjectSelection() {
    //console.log('clear');
    this.projectValue = "0";
    this.selectedProject = null;

    this.filteredProjects = this.projectOptions;
    this.filteredZones = this.zoneOptions;
    if (this.selectedZone != null)
      this.filteredBuildings = this.buildingOptions.filter((option) => option.zoneId === this.selectedZone);
    else
      this.filteredBuildings = this.buildingOptions;
    //this.currentPage = 1;
    //this.filterUnits(); // Reapply filters after clearing
  }
  clearZoneSelection() {
    //console.log('clear');
    this.zoneValue = "0";
    this.selectedZone = null;
    this.filteredProjects = this.projectOptions;
    if (this.selectedProject != null) {
      this.filteredZones = this.zoneOptions.filter((option) => option.projectId === this.selectedProject);
      this.filteredBuildings = this.buildingOptions.filter((option) => option.projectId === this.selectedProject);
    }
    else {
      this.filteredZones = this.zoneOptions;
      this.filteredBuildings = this.buildingOptions;
    }
    //this.currentPage = 1;
    //this.filterUnits(); // Reapply filters after clearing
  }
  clearBuildingSelection() {
    //console.log('clear');
    this.buildingValue = "0";
    this.selectedBuilding = null;

    this.filteredProjects = this.projectOptions;
    if (this.selectedProject != null)
      this.filteredZones = this.zoneOptions.filter((option) => option.projectId === this.selectedProject);
    else
      this.filteredZones = this.zoneOptions;

    if (this.selectedZone != null) {
      this.filteredBuildings = this.buildingOptions.filter((option) => option.zoneId === this.selectedZone);
    }
    else if (this.selectedProject != null) {
      this.filteredBuildings = this.buildingOptions.filter((option) => option.projectId === this.selectedProject);
    }
    else {
      this.filteredBuildings = this.buildingOptions;
    }
    //this.currentPage = 1;
    //this.filterUnits(); // Reapply filters after clearing
  }

  handleNextPage() {
    if (!this.isLastPage) {
      this.currentPage++;
    }
  }

  handlePreviousPage() {
    if (!this.isFirstPage) {
      this.currentPage--;
    }
  }

  get paginatedUnits() {
    //console.log('paginated');
    const start = (this.currentPage - 1) * this.pageSize;
    return this.filteredUnits.slice(start, start + this.pageSize);
  }
  handleRowUnitSelection(event) {
    try {
      console.log("eventDetails," + JSON.stringify(event.detail));
      const selectedRows = event.detail.selectedRows;
      console.log("preselecreRow" + this.preselectedRowIds);
      // this.selectedUnit = selectedRows[0] ;
      this.unitId = selectedRows[0].unitId;
      this.unitHREF = this.unitHREF += this.unitId;
      this.unitHREF += "/view";
      refreshApex(this.UnitwiredRecord);
      console.log("after the refresh apex");
    } catch (error) { }
  }
  renderedCallback() {
    // const datatable1 = this.template.querySelector('lightning-datatable[data-id="contract"]');
    //console.log('dataTable'+ datatable1);
    /*   if(this.selectedContractId ){
               console.log('in the condition'+this.selectedContractId);
               //this.selectedContractId = selectedRows[0].Id;
               //this.contractDetails = selectedRows[0].Unit_Contracts__r;
               setTimeout(
                   () => this.ContractDetailselectedRowIds = this.khidmahUnitContracts
           .filter(record => record.Id === this.selectedContractId) // Find the matching record(s)
           .map(record => record.Id), console.log('in the timout'))
           console.log('after timeout');
   
           }*/
  }

  connectedCallback() {
    this.ContractDetailselectedRowIds = [this.selectedContractDetailId];
    this.ContractselectedRowIds = [this.selectedContracId];
    if (this.accountSelectedRecordInput) {
      this.accountId = this.accountSelectedRecordInput.Id;
      this.accountRec = this.accountSelectedRecordInput;
      this.accHREF += this.accountSelectedRecordInput.Id;
      this.accHREF += "/view";
    }
    if (this.editCheck) {
      this.isLoading = false;
    }

    if (this.preselectedRowIds) {
      console.log("preselectedrowid" + this.preselectedRowIds);
      this.unitId = this.preselectedRowIds;
      this.unitHREF += this.preselectedRowIds;
      this.unitHREF += "/view";
    }
    //get the recordTypes available for ECSS
    console.log("In connectedCallback");
    getRecTypes().then((result) => {
      console.log("res:" + JSON.stringify(result));
      result.forEach((recordType) => {
        let labelWithoutPrefix = recordType.label.replace(/^ecss\s*/i, ""); // Removes 'ecss' and any whitespace after it
        console.log("labelWithoutPrefix" + labelWithoutPrefix);
        if (
          !labelWithoutPrefix.toLowerCase().includes("khidmah") &&
          !labelWithoutPrefix.toLowerCase().includes("email") &&
          !labelWithoutPrefix.toLowerCase().includes("phone")
        ) {
          this.PickListCaseRecordTypes.push({
            label: labelWithoutPrefix,
            value: recordType.value
          });
        }

        this.caseRecordTypes.push({
          label: recordType.label,
          value: recordType.value
        });

        console.log("recordType check:");
      });
      this.caseTypeOptions = this.PickListCaseRecordTypes;
      this.caseTypeFilteredOptions = this.PickListCaseRecordTypes;

      //In case of editting to preview pre-existing values//
      if (this.caseTypeSelectedValue && this.typeEditCheck) {
        this.typeEditCheck = false;
        this.caseTypeSearchKey = this.caseTypeOptions.find(
          (option) => option.value === this.caseTypeSelectedValue
        ).label;
        this.caseTypeFilteredOptions = [];
        this.caseTypePlaceholderText = this.caseTypeSearchKey; // Show the selected option as placeholder text
        this.caseTypeDropdownVisible = false; // Hide the dropdown after selection
        try {
          refreshApex(this.wiredObjectInfo);
        } catch (error) {
          console.log(error);
        }
      }
      //Editting End//
    });

    getAccRecTypes().then((result) => {
      console.log("res:" + JSON.stringify(result));
      result.forEach((recordType) => {
        this.accountRecordTypes.push({
          label: recordType.label,
          value: recordType.value
        });
        this.typeValueMap.set(recordType.value, recordType.label);
        console.log("recordType check:");
      });
      this.accountTypeOptions = this.accountRecordTypes;
      this.accountTypeFilteredOptions = this.accountRecordTypes;
    });
    /* getCompanyFromManagedBy({ecssUnitId:this.unitId})
         .then(data=>{
             this.companyWrapMap =new Map(Object.entries(data)); 
             console.log('Map',this.companyWrapMap);
             this.companyWrapMap.forEach(cmp=>
                 {   console.log('COMPANY:',cmp.companyName);
                     //this.buildingOptions.push({ label: item.buildingName, value: item.buildingId })
                    this.companyOptions.push({label: cmp.companyName, value: cmp.companyId});
                 }
             );
             this.companyFilteredOptions = this.companyOptions;
             console.log('this.companySelectedValue'+this.companySelectedValue);
           //In case of editting to preview pre-existing values//
             if(this.compEditCheck && this.companySelectedValue){
                 this.compEditCheck = false;
                 console.log('in the companyselectedvalue');
                 this.companySearchKey = this.companyOptions.find(option => option.value === this.companySelectedValue).label;
                 this.companyFilteredOptions = [];
                 this.companyPlaceholderText = this.categorySearchKey; // Show the selected option as placeholder text
                 this.companyDropdownVisible = false; // Hide the dropdown after selection
                 this.companyId = this.companySelectedValue;
                 this.chosenCompanyId = this.companySelectedValue;
                 this.chosenCompanyName = this.companyWrapMap.get(this.companySelectedValue).companyName;
                 this.companyHREF += this.chosenCompanyId;
                 this.companyHREF += '/view';
                // this.getKhidmahContrats();
                 if (this.chosenCompanyName.includes('Khidmah')) {
                     this.isKhidmah = true;
                 } else {
                     this.isKhidmah = false;
                 }
             }
             //Editting End//
         })
         .catch(error =>{
             console.log(error);
         })*/
    console.log("before the getRelatedContacts");
    console.log("accountId:" + this.accountId);
    if (this.accountId != "") {
      console.log("entered here in contact");
      getRelatedContacts({ accId: this.accountId, assetId: this.unitId })
        .then((result) => {
          console.log("Contactres:" + JSON.stringify(result));
          if (!result || result == '' || result.length == 0) {
            console.log('entered hereee : ', result);
            this.contactSelectionPreview = true;
          }
          result.forEach((conta) => {
            this.contactoptions.push({
              label: conta.Name,
              value: conta.Idval
            });
            if (!conta.isPerson) {
              this.contactSelectionPreview = true;
            } else {
              this.isPerson = true;
              this.contactId = conta.Idval;
            }
            this.contactValueMap.set(recordType.value, recordType.label);
          });
          this.contactFilteredOptions = this.contactoptions;
        })
        .catch((error) => {
          console.log("in the conterr");
          console.log(error);
        });
      // this.getKhidmahContrats();
    }

    document.addEventListener("click", this.categoryHandleClickOutside);
     document.addEventListener("click", this.subCategoryHandleClickOutside);
     document.addEventListener("click", this.caseTypeHandleClickOutside);
     document.addEventListener("click", this.subVerticalHandleClickOutside);
     document.addEventListener("click", this.objectCategoryHandleClickOutside);
     document.addEventListener("click", this.companyHandleClickOutside);
     document.addEventListener("click", this.caseOriginHandleClickOutside);
  }

  disconnectedCallback() {
    document.removeEventListener("click", this.categoryHandleClickOutside);
     document.removeEventListener("click", this.subCategoryHandleClickOutside);
     document.removeEventListener("click", this.caseTypeHandleClickOutside);
     document.removeEventListener("click", this.subVerticalHandleClickOutside);
     document.removeEventListener(
       "click",
       this.objectCategoryHandleClickOutside
     );
     document.removeEventListener("click", this.companyHandleClickOutside);
     document.removeEventListener("click", this.caseOriginHandleClickOutside);
  }

  //get filteredCategroyOptions() {
  //     console.log('entered in the filter');
  //      return this.categoryFilteredOptions.filter(option => option.validFor.includes(this.subVerticalSelectedValue));
  //  }
  handleContactFetch() {
    console.log("accId:" + this.accountId);
    console.log("in the fetch contacts");
    var tmpAccId = this.accountId;
    if (this.cAccountId != '' || this.cAccountId != null)
      tmpAccId = this.cAccountId;
    getRelatedContacts({ accId: this.accountId, assetId: this.unitId })
      .then((result) => {
        this.contactFilteredOptions = [];
        this.contactoptions = [];
        console.log("Contactres:" + JSON.stringify(result));
        if (result.length == 0) {
          this.contactSelectionPreview = true;
        }
        result.forEach((conta) => {
          this.contactoptions.push({
            label: conta.Name,
            value: conta.Idval
          });
          this.isPerson = conta.isPerson;
          if (!conta.isPerson || this.assetAccExists) {
            this.contactSelectionPreview = true;
          } else {
            this.contactId = conta.Idval;
          }
          this.contactValueMap.set(recordType.value, recordType.label);
        });
        this.contactFilteredOptions = this.contactoptions;
      })
      .catch((error) => {
        console.log("in the conterr");
        console.log(error);
      });
  }

  ///////Category Methods///////
  // Toggle the dropdown when the user clicks inside the input
  categoryToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.categoryDropdownVisible = !this.categoryDropdownVisible;
    if (this.companyDropdownVisible) this.companyDropdownVisible = false;
    if (this.subVerticalDropdownVisible)
      this.subVerticalDropdownVisible = false;
    if (this.objectCategoryDropdownVisible)
      this.objectCategoryDropdownVisible = false;
    if (this.subCategoryDropdownVisible)
      this.subCategoryDropdownVisible = false;
    if (this.caseTypeDropdownVisible) this.caseTypeDropdownVisible = false;
    if (this.caseOriginDropdownVisible) this.caseOriginDropdownVisible = false;
    if (this.customerTypeDropDownVisible)
      this.customerTypeDropDownVisible = false;
  }

  categoryCloseDropdown() {
    this.categoryDropdownVisible = false;
  }

  handleCategorySearchKeyChange(event) {
    this.clearCategoryInput();

    this.categorySearchKey = event.target.value;
    if (this.categorySearchKey == "") {
      this.clearCategoryInput();
      this.refreshApex(subCategoryValues);
      this.refreshApex(objectCategoryValues);
    }
    var categoryFilteredAllValues = this.caseCategoryOptions;
    if (
      this.subVerticalSelectedValue != "" &&
      this.subVerticalSelectedValue != null
    ) {
      let key =
        this.categoryPickListData.controllerValues[
        this.subVerticalSelectedValue
        ];
      this.categoryFilteredOptions = this.categoryPickListData.values.filter(
        (opt) => opt.validFor.includes(key)
      );
      categoryFilteredAllValues = this.categoryFilteredOptions;
    }
    this.categoryFilteredOptions = categoryFilteredAllValues.filter((option) =>
      option.label.toLowerCase().includes(this.categorySearchKey.toLowerCase())
    );
    // If no results, show a "No results" message
    this.categorynoResults = this.categoryFilteredOptions.length === 0;
  }

  handleCategorySelection(event) {
    this.clearCategoryInput();
    console.log(
      "Category Selection currency Vlaue :" + event.currentTarget.dataset.value
    );
    this.categorySelectedValue = event.currentTarget.dataset.value;
    this.categorySearchKey = this.caseCategoryOptions.find(
      (option) => option.value === this.categorySelectedValue
    ).label;
    // this.categoryFilteredOptions = [];
    this.categoryPlaceholderText = this.categorySelectedValue; // Show the selected option as placeholder text
    this.categoryDropdownVisible = false; // Hide the dropdown after selection

    //clear the selected value for category
    this.subCategorySelectedValue = "";
    //clear the place holder
    this.subCategoryPlaceholderText = "Search and select";

    this.clearSubCategoryInput();
    //SFMAINTENANCE
    this.refreshApex(subCategoryValues);
    this.refreshApex(objectCategoryValues);
    ////
    // Now filter category options based on the selected subcategory from the metadata
    /*subCategoryValues({Category:this.categorySearchKey,SubVertical:this.subVerticalSearchKey,chosenType:this.caseTypeSearchKey, ObjectCateogry:this.objectCategorySelectedValue})
        .then(result=>{
            this.subCategoryFilteredOptions = [];
            this.subCategoryFilteredOptions = result
            .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
            .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
  
            
            this.subCaseCategoryOptions = this.subCategoryFilteredOptions;
            
        })*/

    //let key = this.subCategoryPickListData.controllerValues[this.categorySelectedValue];
    //this.subCategoryFilteredOptions = this.subCategoryPickListData.values.filter(opt => opt.validFor.includes(key));
  }

  get categoryDropdownClass() {
    return this.categoryDropdownVisible ? "slds-is-open" : "";
  }

  categoryHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.categoryCloseDropdown();
    }
  };

  /////SubCategory Methods////

  // Toggle the dropdown when the user clicks inside the input
  subCategoryToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.subCategoryDropdownVisible = !this.subCategoryDropdownVisible;
    if (this.companyDropdownVisible) this.companyDropdownVisible = false;
    if (this.categoryDropdownVisible) this.categoryDropdownVisible = false;
    if (this.objectCategoryDropdownVisible)
      this.objectCategoryDropdownVisible = false;
    if (this.subVerticalDropdownVisible)
      this.subVerticalDropdownVisible = false;
    if (this.caseTypeDropdownVisible) this.caseTypeDropdownVisible = false;
    if (this.caseOriginDropdownVisible) this.caseOriginDropdownVisible = false;
    if (this.customerTypeDropDownVisible)
      this.customerTypeDropDownVisible = false;
  }

  subCategoryCloseDropdown() {
    this.subCategoryDropdownVisible = false;
  }

  handlesubCategorySearchKeyChange(event) {
    console.log("event" + event);
    console.log("event.target" + event.target);
    console.log("event.target.value" + event.target.value);
    this.subCategorySearchKey = event.target.value.toLowerCase();
    console.log("this.subCategorySearchKey:", this.subCategorySearchKey);
    console.log("this.subCaseCategoryOptions", this.subCaseCategoryOptions);
    this.subCategoryFilteredOptions = this.subCaseCategoryOptions.filter(
      (option) => option.label.toLowerCase().includes(this.subCategorySearchKey)
    );

    // this.subCategorynoResults = this.subCategoryFilteredOptions.length === 0;
  }

  handlesubCategorySelection(event) {
    console.log(
      "event.currentTarget.dataset.value:",
      event.currentTarget.dataset.value
    );
    this.subCategorySelectedValue = event.currentTarget.dataset.value;
    const selectedOption = this.subCaseCategoryOptions.find(
      (option) => option.value === this.subCategorySelectedValue
    );
    if (selectedOption) {
      this.subCategorySearchKey = selectedOption.label; // Update search key to display label
      this.subCategoryPlaceholderText = selectedOption.label; // Set placeholder
    }
    this.subCategoryFilteredOptions = [];
    this.subCategoryPlaceholderText = this.subCategorySearchKey; // Show the selected option as placeholder text
    this.subCategoryDropdownVisible = false; // Hide the dropdown after selection
    // Now filter category options based on the selected subcategory from the metadata
    /* derivedValues({chosenType:this.caseTypeSearchKey,SubVertical:this.subVerticalSearchKey,subCategory:this.subCategorySelectedValue})
         .then(result=>{
             if(result !== null && result !== undefined) {
                 console.log('in the derived valyes:'+result.categoryName);
                 console.log('in the derived valyes:'+result.objectCatName);
                 if(!this.categorySelectedValue){
                     this.categorySearchKey = result.categoryName;
                     this.categorySelectedValue = result.categoryName;
                     console.log('caseCateogrySelectedValeu'+ this.categorySelectedValue);
                     this.categoryPlaceholderText = this.categorySearchKey; // Show the selected option as placeholder text
                 }
                  //   this.objectCategorySearchKey = result.objectCatName;
                  //   this.objectCategorySelectedValue = result.objectCatName;
                 //    console.log('caseCateogrySelectedValeu'+ this.subCategorySelectedValue);
                  //   this.subCategoryPlaceholderText = result.objectCatName; // Show the selected option as placeholder text*/

    //        }
    // this.refreshApex(objectCategoryValues);

    /* else{
         objectCategoryValues({chosenType:this.caseTypeSearchKey,Category:this.categorySearchKey,SubVertical:this.subVerticalSearchKey,subCategory:this.subCategorySelectedValue})
         .then(result=>{
             this.objectCategoryFilteredOptions = [];
             this.objectCategoryFilteredOptions = result
             .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
             .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
             this.objectCaseCategoryOptions = this.objectCategoryFilteredOptions;
         })
     }*/
    //})
  }

  get subCategoryDropdownClass() {
    return this.subCategoryDropdownVisible ? "slds-is-open" : "";
  }

  subCategoryHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.subCategoryCloseDropdown();
    }
  };

  /////ObjectCategory Methods////

  // Toggle the dropdown when the user clicks inside the input
  objectCategoryToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.objectCategoryDropdownVisible = !this.objectCategoryDropdownVisible;
    if (this.companyDropdownVisible) this.companyDropdownVisible = false;
    if (this.categoryDropdownVisible) this.categoryDropdownVisible = false;
    if (this.subVerticalDropdownVisible)
      this.subVerticalDropdownVisible = false;
    if (this.subCategoryDropdownVisible)
      this.subCategoryDropdownVisible = false;
    if (this.caseTypeDropdownVisible) this.caseTypeDropdownVisible = false;
    if (this.caseOriginDropdownVisible) this.caseOriginDropdownVisible = false;
    if (this.customerTypeDropDownVisible)
      this.customerTypeDropDownVisible = false;
  }

  objectCategoryCloseDropdown() {
    this.objectCategoryDropdownVisible = false;
  }

  handleobjectCategorySearchKeyChange(event) {
    this.clearobjectCategoryInput();
    /* if (
      this.objectCategorySearchKey == "" &&
      !(
        this.caseTypeSearchKey.includes("Maintenance") ||
        this.caseTypeSearchKey.includes("Request")
      )
    ) {
      this.clearCategoryInput();
    }*/
    this.objectCategorySearchKey = event.target.value.toLowerCase();
    console.log("this.objectCategorySearchKey:", this.objectCategorySearchKey);

    this.objectCategoryFilteredOptions = this.objectCaseCategoryOptions.filter(
      (option) =>
        option.label.toLowerCase().includes(this.objectCategorySearchKey)
    );

    /*  this.objectCategorynoResults =
      this.objectCategoryFilteredOptions.length === 0;*/
  }

  handleobjectCategorySelection(event) {
    this.clearobjectCategoryInput();
    console.log("Selected value:", event.currentTarget.dataset.value);
    this.objectCategorySelectedValue = event.currentTarget.dataset.value;

    const selectedOption = this.objectCaseCategoryOptions.find(
      (option) => option.value === this.objectCategorySelectedValue
    );
    if (selectedOption) {
      this.objectCategorySearchKey = selectedOption.label; // Update search key to display label
      this.objectCategoryPlaceholderText = selectedOption.label; // Set placeholder
    }
    this.objectCategoryFilteredOptions = [];
    this.objectCategoryPlaceholderText = this.objectCategorySearchKey; // Show the selected option as placeholder text
    this.objectCategoryDropdownVisible = false; // Hide the dropdown after selection

    console.log("in the else of the derived value");
    /* subCategoryValues({Category:this.categorySearchKey,SubVertical:this.subVerticalSearchKey,chosenType:this.caseTypeSearchKey,ObjectCateogry:this.objectCategorySelectedValue})
         .then(result=>{
             this.subCategoryFilteredOptions = [];
             this.subCategoryFilteredOptions = result
             .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
             .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
   
             
             this.subCaseCategoryOptions = this.subCategoryFilteredOptions;
             
         }) */
    //SFMAINTENANCE
     if (!this.isMaintenance) this.refreshApex(subCategoryValues);
  }

  get objectCategoryDropdownClass() {
    return this.objectCategoryDropdownVisible ? "slds-is-open" : "";
  }

  objectCategoryHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.objectCategoryCloseDropdown();
    }
  };

  /////AccountType Methods////
  // Handle accountName input change
  async handleAccNameChange(event) {
    let name = event.target.name;
    let val = event.target.value;
    if (name == "accName") this.accName = val;
    if (name == "registrationNumber") {
      console.log("In the registration No Check : ");
      this.duplicateRegNo = false;
      this.accRegisNo = val;
      this.duplicateRegNo = await this.handleAccDuplicateCheck();
    }
    if (name == "passportNo") {
      this.duplicatePassportAcc = false;
      this.accPasspNo = val;
      this.duplicatePassportAcc = await this.handleAccDuplicateCheck();
    }
    if (name == "emiratesId") {
      this.duplicateEmiratesAcc = false;
      this.accEmiratesId = val;
      this.duplicateEmiratesAcc = await this.handleAccDuplicateCheck();
    }
    if (name == "accEmail") {
      this.duplicateEmailAcc = false;
      this.accEmail = val;
      console.log("before Duplicate Email");
      this.duplicateEmailAcc = await this.handleAccDuplicateCheck();
      console.log("after Duplicate Email:" + this.duplicateEmailAcc);
    }
    if (name == "countryCode") this.countryCode = val;
    if (name == "MobilePhone") {
      this.contactPhoneInvalid = false;
      this.duplicateMobiletAcc = false;
      this.mobilePhone = val;
      this.duplicateMobiletAcc = await this.handleAccDuplicateCheck();
    }
    if (name == "firstName") {
      this.accFirstName = val;
    }
    if (name == "middleName") {
      this.accMiddleName = val;
    }
    if (name == "lastName") {
      this.accLastName = val;
    }
    if (name == "floor") {
      this.accFloor = val;
    }
    if (name == "apartmentNumber") {
      this.accApartmentNumber = va;
    }
    if (name == "packageType") {
      this.accPackageType = val;
    }
    if (name == "contractNumber") {
      this.contactPhoneInvalid = false;
      this.accContractNo = val;
    }
    if (name == "streetNo") {
      this.accStreetNo = val;
    }
    if (name == "streetName") {
      this.accStreetName = val;
    }
    if (name == "zipCode") {
      this.accZipCode = val;
    }
    if (name == "contractNumber") {
      this.accContractNo = val;
    }
  }
  // Toggle the dropdown when the user clicks inside the input
  accountTypeToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.accountTypeDropdownVisible = !this.accountTypeDropdownVisible;
  }

  accountTypeCloseDropdown() {
    this.accountTypeDropdownVisible = false;
  }

  handleaccountTypeSearchKeyChange(event) {
    this.accountTypeSearchKey = event.target.value.toLowerCase();
    this.accountTypeFilteredOptions = this.accountTypeOptions.filter((option) =>
      option.label.toLowerCase().includes(this.accountTypeSearchKey)
    );
    // If no results, show a "No results" message
    this.accountTypeNoResults = this.accountTypeFilteredOptions.length === 0;
  }

  handleaccountTypeSelection(event) {
    this.accountIsPerson = false;
    this.accountIsComp = false;
    this.isPerson = false;
    this.accountTypeSelectedValue = event.currentTarget.dataset.value;
    this.accountTypeSelectedLabel = this.typeValueMap.get(
      this.accountTypeSelectedValue
    );
    if (this.accountTypeSelectedLabel.trim().toLowerCase().includes("person")) {
      this.accountIsPerson = true;
      this.isPerson = true;
    } else if (this.accountTypeSelectedLabel != "") {
      this.accountIsComp = true;
    }
    this.accountTypeSearchKey = this.accountTypeOptions.find(
      (option) => option.value === this.accountTypeSelectedValue
    ).label;
    this.accountTypeFilteredOptions = [];
    this.accountTypePlaceholderText = this.caseTypeSearchKey; // Show the selected option as placeholder text
    this.accountTypeDropdownVisible = false; // Hide the dropdown after selection
    try {
      refreshApex(this.wiredObjectInfo);
    } catch (error) {
      console.log(error);
    }
  }

  get caseTypeDropdownClass() {
    return this.caseTypeDropdownVisible ? "slds-is-open" : "";
  }

  caseTypeHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.caseTypeCloseDropdown();
    }
  };

  /////Case Type Methods////

  // Toggle the dropdown when the user clicks inside the input
  caseTypeToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.caseTypeDropdownVisible = !this.caseTypeDropdownVisible;
    if (this.companyDropdownVisible) this.companyDropdownVisible = false;
    if (this.categoryDropdownVisible) this.categoryDropdownVisible = false;
    if (this.objectCategoryDropdownVisible)
      this.objectCategoryDropdownVisible = false;
    if (this.subCategoryDropdownVisible)
      this.subCategoryDropdownVisible = false;
    if (this.subVerticalDropdownVisible)
      this.subVerticalDropdownVisible = false;
    if (this.caseOriginDropdownVisible) this.caseOriginDropdownVisible = false;
    if (this.customerTypeDropDownVisible)
      this.customerTypeDropDownVisible = false;
  }

  caseTypeCloseDropdown() {
    this.caseTypeDropdownVisible = false;
  }

  handleCaseTypeSearchKeyChange(event) {
    this.caseTypeSearchKey = event.target.value.toLowerCase();
    this.caseTypeFilteredOptions = this.caseTypeOptions.filter((option) =>
      option.label.toLowerCase().includes(this.caseTypeSearchKey)
    );
    // If no results, show a "No results" message
    this.caseTypeNoResults = this.caseTypeFilteredOptions.length === 0;
  }

  handleCaseTypeSelection(event) {
    this.clearCompanyInput();
    this.companyDisabled = false;
    this.isCompanyLoading = true;
    this.caseTypeSelectedValue = event.currentTarget.dataset.value;
    this.caseTypeSearchKey = this.caseTypeOptions.find(
      (option) => option.value === this.caseTypeSelectedValue
    ).label;
    this.caseTypeFilteredOptions = [];
    this.caseTypePlaceholderText = this.caseTypeSearchKey; // Show the selected option as placeholder text
    this.caseTypeDropdownVisible = false; // Hide the dropdown after selection
    if (
      this.caseTypeSearchKey.includes("Maintenance") ||
      this.caseTypeSearchKey.includes("Request")
    ) {
      this.AccountCreationLabel = "Request Account Creation";
      this.isMaintenance = true;
      if (!this.accountCreationCheckbox) {
        //add the autoselection of contracts
        this.preSelectedContractDetails = this.preSelectedContractDetailsTemp;
        this.preSelectedContracts = this.preSelectedContractsTemp;
        this.preSelectedContractId = this.preSelectedContracts[0];
        this.preSelectedContractDetailId = preSelectedContractDetails[0];
      } else {
        this.showContracts = false;
      }
      /*objectCategoryValues({chosenType:this.caseTypeSearchKey,Category:this.categorySearchKey,SubVertical:this.subVerticalSearchKey,subCategory:this.subCategorySelectedValue})
            .then(result=>{
                this.objectCategoryFilteredOptions = [];
                this.objectCategoryFilteredOptions = result
                .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
                .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
                this.objectCaseCategoryOptions = this.objectCategoryFilteredOptions;
  
            })*/
      this.refreshApex(picklistValuesCaseType);
      this.refreshApex(objectCategoryValues);
      /*  subCategoryValues({Category:this.categorySearchKey,SubVertical:this.subVerticalSearchKey,chosenType:this.caseTypeSearchKey,ObjectCateogry:this.objectCategorySelectedValue})
              .then(result=>{
                  this.subCategoryFilteredOptions = [];
                  this.subCategoryFilteredOptions = result
                  .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
                  .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
      
                  
                  this.subCaseCategoryOptions = this.subCategoryFilteredOptions;
                  
              })*/
      this.clearSubCategoryInput();
      this.refreshApex(subCategoryValues);
    } else {
      this.AccountCreationLabel = "Request Account Creation";
      if (this.isKhidmah) {
        this.isMaintenance = true;
        this.preSelectedContractDetails = this.preSelectedContractDetailsTemp;
        this.preSelectedContracts = this.preSelectedContractsTemp;
        this.preSelectedContractId = this.preSelectedContracts[0];
        this.preSelectedContractDetailId = preSelectedContractDetails[0];
      } else {
        this.isMaintenance = false;
        //remove the autoselection of contracts
        this.preSelectedContractDetails = [];
        this.preSelectedContracts = [];
        this.preSelectedContractId = "";
        this.preSelectedContractDetailId = "";
        this.selectedContracId = "";
        this.selectedContractDetailId = "";
      }
    }

    try {
      refreshApex(this.wiredObjectInfo);
    } catch (error) {
      console.log(error);
    }
  }

  get caseTypeDropdownClass() {
    return this.caseTypeDropdownVisible ? "slds-is-open" : "";
  }

  caseTypeHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.caseTypeCloseDropdown();
    }
  };

  /////Sub Vertical Methods////

  // Toggle the dropdown when the user clicks inside the input
  subVerticalToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.subVerticalDropdownVisible = !this.subVerticalDropdownVisible;
    if (this.companyDropdownVisible) this.companyDropdownVisible = false;
    if (this.categoryDropdownVisible) this.categoryDropdownVisible = false;
    if (this.objectCategoryDropdownVisible)
      this.objectCategoryDropdownVisible = false;
    if (this.subCategoryDropdownVisible)
      this.subCategoryDropdownVisible = false;
    if (this.caseTypeDropdownVisible) this.caseTypeDropdownVisible = false;
    if (this.caseOriginDropdownVisible) this.caseOriginDropdownVisible = false;
    if (this.customerTypeDropDownVisible)
      this.customerTypeDropDownVisible = false;
  }

  subVerticalCloseDropdown() {
    this.subVerticalDropdownVisible = false;
  }

  handleSubVerticalSearchKeyChange(event) {
    this.clearCategoryInput();
    this.subVerticalSearchKey = event.target.value.toLowerCase();
    if (this.subVerticalSearchKey == "") {
      this.clearSubVerticalInput();
    }
    var subverticalFilterConst = this.subVerticalOptions;
    if (this.companySelectedValue != "" && this.companySelectedValue != null) {
      let key =
        this.subVerticalDataValue.controllerValues[this.companySelectedValue];
      console.log("key value:" + key);
      console.log(
        "subVerticalDataValue:",
        JSON.stringify(this.subVerticalDataValue)
      );
      this.subVerticalFilteredOptions = this.subVerticalDataValue.values.filter(
        (opt) => opt.validFor.includes(key)
      );
      subverticalFilterConst = this.subVerticalFilteredOptions;
    }
    this.subVerticalFilteredOptions = subverticalFilterConst.filter((option) =>
      option.label.toLowerCase().includes(this.subVerticalSearchKey)
    );
    // If no results, show a "No results" message
    this.subVerticalNoResults = this.subVerticalFilteredOptions.length === 0;
  }

  handleSubVerticalSelection(event) {
    // this.clearCategoryInput();
    this.categoryDisabled = false;
    this.objectCategoryDisabled = false;
    this.subCaseCategoryDisabled = false;
    this.subVerticalSelectedValue = event.currentTarget.dataset.value;
    this.subVerticalSearchKey = this.subVerticalOptions.find(
      (option) => option.value === this.subVerticalSelectedValue
    ).label;
    //this.subVerticalFilteredOptions = [];
    this.subVerticalPlaceholderText = this.subVerticalSearchKey; // Show the selected option as placeholder text
    this.subVerticalDropdownVisible = false; // Hide the dropdown after selection
    //clear the selected value for category
    this.categorySelectedValue = "";
    //clear the place holder
    this.categoryPlaceholderText = "Search and select";

    // Now filter category options based on the selected subvertical
    let key =
      this.categoryPickListData.controllerValues[this.subVerticalSelectedValue];
    this.caseCategoryOptions = this.categoryPickListData.values.map(
      (value) => ({
        label: value.label,
        value: value.value
      })
    );
    this.stringifiedCaseCategoryOptions = JSON.stringify(
      this.caseCategoryOptions
    );
    this.categoryFilteredOptions = this.categoryPickListData.values.filter(
      (opt) => opt.validFor.includes(key)
    );
    if (this.categoryFilteredOptions.length == 1) {
      this.categoryDisabled = false;
      this.objectCategoryDisabled = false;
      this.subCaseCategoryDisabled = false;
      this.categorySearchKey = this.categoryFilteredOptions[0].label;
      this.categorySelectedValue = this.categoryFilteredOptions[0].value;
      console.log("caseCateogrySelectedValeu" + this.categorySelectedValue);
      this.categoryPlaceholderText = this.categorySearchKey;
    }

    /*objectCategoryValues({chosenType:this.caseTypeSearchKey,Category:this.categorySearchKey,SubVertical:this.subVerticalSearchKey,subCategory:this.subCategorySelectedValue})
        .then(result=>{
            this.objectCategoryFilteredOptions = [];
            this.objectCategoryFilteredOptions = result
            .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
            .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
            this.objectCaseCategoryOptions = this.objectCategoryFilteredOptions;
  
        })*/
    this.refreshApex(objectCategoryValues);
    this.refreshApex(categoryReturnValues);
    this.clearSubCategoryInput();
    this.refreshApex(subCategoryValues);
    /*  subCategoryValues({Category:this.categorySearchKey,SubVertical:this.subVerticalSearchKey,chosenType:this.caseTypeSearchKey,ObjectCateogry:this.objectCategorySelectedValue})
          .then(result=>{
              this.subCategoryFilteredOptions = [];
              this.subCategoryFilteredOptions = result
              .filter(conta => conta && conta.valName) // Filter out falsy items and items without `valName`
              .map(conta => ({ label: conta.valName, value: conta.valName })); // Map directly to the desired format
   
              
              this.subCaseCategoryOptions = this.subCategoryFilteredOptions;
              
          })*/
  }

  get subVerticalDropdownClass() {
    return this.subVerticalDropdownVisible ? "slds-is-open" : "";
  }

  subVerticalHandleClickOutside = (event) => {
    // console.log('toggle event');
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.subVerticalCloseDropdown();
    }
  };
  /////////////////////////
  // Case Origin Methods

  // Toggle the dropdown when the user clicks inside the input
  caseOriginToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.caseOriginDropdownVisible = !this.caseOriginDropdownVisible;
    if (this.companyDropdownVisible) this.companyDropdownVisible = false;
    if (this.categoryDropdownVisible) this.categoryDropdownVisible = false;
    if (this.subVerticalDropdownVisible)
      this.subVerticalDropdownVisible = false;
    if (this.subCategoryDropdownVisible)
      this.subCategoryDropdownVisible = false;
    if (this.objectCategoryCloseDropdown)
      this.objectCategoryCloseDropdown = false;
    if (this.caseTypeDropdownVisible) this.caseTypeDropdownVisible = false;
  }

  caseOriginCloseDropdown() {
    this.caseOriginDropdownVisible = false;
  }

  handleCaseOriginSearchKeyChange(event) {
    this.caseOriginSearchKey = event.target.value.toLowerCase();
    this.caseOriginFilteredOptions = this.caseOriginOptions.filter((option) =>
      option.label.toLowerCase().includes(this.caseOriginSearchKey)
    );
    this.caseOriginNoResults = this.caseOriginFilteredOptions.length === 0;
  }

  handleCaseOriginSelection(event) {
    this.caseOriginSelectedValue = event.currentTarget.dataset.value;
    this.caseOriginSearchKey = this.caseOriginOptions.find(
      (option) => option.value === this.caseOriginSelectedValue
    ).label;
    this.caseOriginFilteredOptions = [];
    this.caseOriginPlaceholderText = this.caseOriginSearchKey; // Show the selected option as placeholder text
    this.caseOriginDropdownVisible = false; // Hide the dropdown after selection
  }
  /////////////////COMPANY CHOICE///////////////c/createNewCase ///////Category Methods///////
  // Toggle the dropdown when the user clicks inside the input
  companyToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.companyDropdownVisible = !this.companyDropdownVisible;
    if (this.subVerticalDropdownVisible)
      this.subVerticalDropdownVisible = false;
    if (this.categoryDropdownVisible) this.categoryDropdownVisible = false;
    if (this.objectCategoryDropdownVisible)
      this.objectCategoryDropdownVisible = false;
    if (this.subCategoryDropdownVisible)
      this.subCategoryDropdownVisible = false;
    if (this.caseOriginDropdownVisible) this.caseOriginDropdownVisible = false;
  }

  companyCloseDropdown() {
    this.companyDropdownVisible = false;
  }

  handlecompanySearchKeyChange(event) {
    this.clearSubVerticalInput();
    this.companySearchKey = event.target.value;
    if (this.companySearchKey == "") {
      this.clearCompanyInput();
    }
    this.companyFilteredOptions = this.companyFilteredOptions.filter((option) =>
      option.label.toLowerCase().includes(this.companySearchKey.toLowerCase())
    );
    // If no results, show a "No results" message
    this.companyNoResults = this.companyFilteredOptions.length === 0;
  }

  handlecompanySelection(event) {
    this.clearSubVerticalInput();
    this.subVerticalDisabled = false;
    console.log("in the company selection");
    this.companySelectedValue = event.currentTarget.dataset.value;
    this.companySearchKey = this.companyOptions.find(
      (option) => option.value === this.companySelectedValue
    ).label;
    // this.companyFilteredOptions = [];
    this.companyPlaceholderText = this.categorySearchKey; // Show the selected option as placeholder text
    this.companyDropdownVisible = false; // Hide the dropdown after selection
    this.companyId = this.companySelectedValue;
    this.chosenCompanyId = this.companySelectedValue;
    this.chosenCompanyName = this.companySelectedValue;
    //this.companyHREF += this.chosenCompanyId;
    //this.companyHREF += '/view';

    // Now filter category options based on the selected subvertical
    let key =
      this.subVerticalDataValue.controllerValues[this.companySelectedValue];
    console.log("key value:" + key);
    console.log(
      "subVerticalDataValue:",
      JSON.stringify(this.subVerticalDataValue)
    );
    this.subVerticalFilteredOptions = this.subVerticalDataValue.values.filter(
      (opt) => opt.validFor.includes(key)
    );
    console.log(
      "filtered value : ",
      JSON.stringify(this.subVerticalFilteredOptions)
    );
    if (this.subVerticalFilteredOptions.length == 1) {
      this.subVerticalDisabled = false;
      this.categoryDisabled = false;
      this.objectCategoryDisabled = false;
      this.subCaseCategoryDisabled = false;
      this.subVerticalSearchKey = this.subVerticalFilteredOptions[0].label;
      this.subVerticalSelectedValue = this.subVerticalFilteredOptions[0].value;
      console.log("subVerticalSelectedValue" + this.subVerticalFilteredOptions);
      this.subVerticalPlaceholderText = this.subVerticalSearchKey;
      // Now filter category options based on the selected subvertical
      let key =
        this.categoryPickListData.controllerValues[
        this.subVerticalSelectedValue
        ];
      this.caseCategoryOptions = this.categoryPickListData.values.map(
        (value) => ({
          label: value.label,
          value: value.value
        })
      );
      this.stringifiedCaseCategoryOptions = JSON.stringify(
        this.caseCategoryOptions
      );
      this.categoryFilteredOptions = this.categoryPickListData.values.filter(
        (opt) => opt.validFor.includes(key)
      );
      if (this.categoryFilteredOptions.length == 1) {
        this.categoryDisabled = false;
        this.objectCategoryDisabled = false;
        this.subCaseCategoryDisabled = false;
        this.categorySearchKey = this.categoryFilteredOptions[0].label;
        this.categorySelectedValue = this.categoryFilteredOptions[0].value;
        console.log("caseCateogrySelectedValeu" + this.categorySelectedValue);
        this.categoryPlaceholderText = this.categorySearchKey;
      }
    }

    //this.getKhidmahContrats();
    /*this.showContracts = true;
        if (this.chosenCompanyName.includes('Khidmah')) {
            this.isKhidmah = true;
        } else {
            this.isKhidmah = false;
        }*/
  }

  get companyDropdownClass() {
    return this.companyDropdownVisible ? "slds-is-open" : "";
  }

  companyHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.companyCloseDropdown();
    }
  };
  ////////////////////////////Company Choice End//////////////////

  /////////////////CONTACT CHOICE///////////////c/createNewCase ///////Category Methods///////
  // Toggle the dropdown when the user clicks inside the input
  contactToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.contactDropdownVisible = !this.contactDropdownVisible;
  }

  contactCloseDropdown() {
    this.contactDropdownVisible = false;
  }

  handlecontactSearchKeyChange(event) {
    this.contactSearchKey = event.target.value.toLowerCase();
    this.contactFilteredOptions = this.contactoptions.filter((option) =>
      option.label.toLowerCase().includes(this.contactSearchKey)
    );
    // If no results, show a "No results" message
    this.contactNoResults = this.contactFilteredOptions.length === 0;
  }
  handlecontactSelection(event) {
    this.contactRelatedCmpValue = [];
    this.contactSelectedValue = event.currentTarget.dataset.value;
    this.contactSearchKey = this.contactoptions.find(
      (option) => option.value === this.contactSelectedValue
    ).label;
    this.contactFilteredOptions = [];
    this.contactPlaceholderText = this.contactSearchKey; // Show the selected option as placeholder text
    this.contactDropdownVisible = false; // Hide the dropdown after selection
    this.contactId = this.contactSelectedValue;
    this.contactName = this.contactValueMap.get(this.contactSelectedValue).Name;
  }

  get companyDropdownClass() {
    return this.companyDropdownVisible ? "slds-is-open" : "";
  }

  companyHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.companyCloseDropdown();
    }
  };
  ////////////////////////////Company Choice End//////////////////

  ///////Building CHoice methods Methods///////
  // Toggle the dropdown when the user clicks inside the input
  buildingToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.buildingDropdownVisible = !this.buildingDropdownVisible;
  }

  buildingCloseDropdown() {
    this.buildingDropdownVisible = false;
  }
  handleBuildingSearchKeyChange(event) {
    console.log("building search key");
    this.buildingSearchKey = event.target.value.toLowerCase();
    console.log("building search key:" + this.buildingSearchKey);

    // Handle the wildcard behavior: replace '*' with '.*'
    const regexPattern = this.buildingSearchKey.replace(/\*/g, ".*"); // Convert all '*' to regex match
    const regex = new RegExp(regexPattern);

    this.accBuildingFilteredOptions = this.accbuildingOptions.filter(
      (option) => regex.test(option.label.toLowerCase()) // Check if the label matches the regex
    );

    // If no results, show a "No results" message
    this.buildingNoResults = this.accBuildingFilteredOptions.length === 0;
  }

  handleBuildingSelection(event) {
    this.buildingSelectedValue = event.currentTarget.dataset.value;
    this.buildingSearchKey = this.accbuildingOptions.find(
      (option) => option.value === this.buildingSelectedValue
    ).label;
    this.accBuildingFilteredOptions = [];
    this.buildingPlaceholderText = this.categorySearchKey; // Show the selected option as placeholder text
    this.buildingDropdownVisible = false; // Hide the dropdown after selection

    //clear the selected value for unit
    this.assetSelectedValue = "";
    //clear the place holder
    this.assetPlaceholderText = "Search and select";

    // Now filter category options based on the selected subcategory
    let filteredAccAssetOptions = this.accAssetOptions.filter(
      (option) => option.buildingIdval === this.buildingSelectedValue
    );
    console.log("filteredAccAsset" + JSON.stringify(filteredAccAssetOptions));
    this.accAssetFilteredOptions = filteredAccAssetOptions;
  }

  get buildingDropdownClass() {
    return this.buildingDropdownVisible ? "slds-is-open" : "";
  }

  buildingHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.buildingCloseDropdown();
    }
  };

  /////////////////////// Building choice end //////////////////

  /////// Asset CHoice methods Methods///////
  // Toggle the dropdown when the user clicks inside the input
  assetToggleDropdown(event) {
    event.stopPropagation(); // Stop the click from propagating to document
    this.assetDropdownVisible = !this.assetDropdownVisible;
  }

  assetCloseDropdown() {
    this.assetDropdownVisible = false;
  }

  handleAssetSearchKeyChange(event) {
    console.log("In the asset search key change");

    // Get the search key and convert it to lowercase
    this.assetSearchKey = event.target.value.toLowerCase();
    console.log("assetSearchKey:", this.assetSearchKey);

    // Handle the wildcard behavior: replace '*' with '.*'
    const regexPattern = this.assetSearchKey.replace(/\*/g, ".*"); // Convert all '*' to regex match
    const regex = new RegExp(regexPattern); // Create a regular expression object
    //console.log('regexPattern:', regexPattern);
    //console.log('AccAssetOptions:', JSON.stringify(this.accAssetOptions));

    // Filter assets based on the regex pattern matching label or unitCode
    this.accAssetFilteredOptions = this.accAssetOptions.filter(
      (option) =>
        regex.test(option.label.toLowerCase()) || // Match label
        (option.unitCode && regex.test(option.unitCode.toLowerCase())) // Match unitCode if it exists
    );
    //this.searchTerm = event.target.value.toLowerCase();

    // If no results, show a "No results" message
    this.assetNoResults = this.accAssetFilteredOptions.length === 0;

    console.log(
      "accAssetFilteredOptions:",
      JSON.stringify(this.accAssetFilteredOptions)
    );
  }

  handleAssetSelection(event) {
    this.unitsAvailable = false;
    console.log("in the asset selection check");
    this.assetSelectedValue = event.currentTarget.dataset.value;
    this.assetSearchKey = this.accAssetOptions.find(
      (option) => option.value === this.assetSelectedValue
    ).label;
    this.accAssetFilteredOptions = [];
    this.assetPlaceholderText = this.assetSearchKey; // Show the selected option as placeholder text
    this.assetDropdownVisible = false; // Hide the dropdown after selection
    this.unitId = this.assetSelectedValue;
    this.unitHREF = this.unitHREF += this.unitId;
    this.unitHREF += "/view";
    refreshApex(this.UnitwiredRecord);
    refreshApex(this.wiredKhidmahContracts);
    refreshApex(this.wiredAccountRecord);

    //clear the selected value for category
    // this.subCategorySelectedValue = '';
    //clear the place holder
    //this.subCategoryPlaceholderText = 'Search and select';

    // Now filter category options based on the selected subcategory
    //let key = this.subCategoryPickListData.controllerValues[this.categorySelectedValue];
    //this.subCategoryFilteredOptions = this.subCategoryPickListData.values.filter(opt => opt.validFor.includes(key));
  }

  get assetDropdownClass() {
    return this.assetDropdownVisible ? "slds-is-open" : "";
  }

  assetHandleClickOutside = (event) => {
    // Check if the click happened outside the component
    if (!this.template.contains(event.target)) {
      this.assetCloseDropdown();
    }
  };

  /////////////////////// Building choice end //////////////////

  // Handle subject input change
  handleSubjectChange(event) {
    this.subject = event.target.value;
  }

  // Get the dropdown class for Case Origin
  get caseOriginDropdownClass() {
    return this.caseOriginDropdownVisible ? "slds-is-open" : "";
  }

  // Close dropdown on outside click
  caseOriginHandleClickOutside = (event) => {
    if (!this.template.contains(event.target)) {
      this.caseOriginCloseDropdown();
    }
  };

  resetVariables() {
    console.log("test");
    this.clearCaseTypeInput();
    this.clearCompanyInput();
    this.clearaccountTypeInput();
  }
  clearCaseTypeInput() {
    this.companyDisabled = true;
    this.caseTypeSearchKey = ""; // Clear the input
    this.caseTypeFilteredOptions = this.caseTypeOptions; // Reset filtered options
    this.caseTypePlaceholderText = "Search and select";

    //clear the subcertical as well
    this.clearCompanyInput();
  }

  clearSubVerticalInput() {
    console.log("In the clear sub vertical");
    this.categoryDisabled = true;
    this.objectCategoryDisabled = true;
    this.subCaseCategoryDisabled = true;
    this.subVerticalSearchKey = ""; // Clear the input
    // \this.subVerticalFilteredOptions = this.subVerticalOptions; // Reset filtered options
    this.subVerticalPlaceholderText = "Search and select";

    //clear the category as well
    this.clearCategoryInput();

    this.subVerticalSelectedValue = "";
    this.categoryFilteredOptions = [];
    this.caseCategoryOptions = [];
    this.stringifiedCaseCategoryOptions = "";
    this.categorySelectedValue = "";
    this.objectCaseCategoryOptions = [];
    this.objectCategoryFilteredOptions = [];
    this.objectCategorySelectedValue = "";
    this.objectCategorySearchKey = "";
    this.categorySearchKey = "";
    this.subCategorySelectedValue = "";
  }

  clearCategoryInput() {
    this.categorySelectedValue = "";
    this.categorySearchKey = ""; // Clear the input
    console.log(" clear category: this.caseCategoryOptions; ");
    this.categoryFilteredOptions = this.caseCategoryOptions; // Reset filtered options
    if (
      this.subVerticalSelectedValue != "" &&
      this.subVerticalSelectedValue != null
    ) {
      let key =
        this.categoryPickListData.controllerValues[
        this.subVerticalSelectedValue
        ];
      console.log("Category Key:" + key);
      console.log(
        "Category Before: " + JSON.stringify(this.categoryFilteredOptions)
      );
      this.categoryFilteredOptions = this.categoryPickListData.values.filter(
        (opt) => opt.validFor.includes(key)
      );
      console.log(
        "Category ASfter: " + JSON.stringify(this.categoryFilteredOptions)
      );

      this.caseCategoryOptions = this.categoryFilteredOptions;
      this.stringifiedCaseCategoryOptions = JSON.stringify(
        this.caseCategoryOptions
      );
    }
    this.categoryPlaceholderText = "Search and select";
    //this.subCaseCategoryOptions = [];
    this.subCategoryFilteredOptions = this.subCaseCategoryOptions;
    if (!this.isMaintenance) {
      this.objectCategorySearchKey = ""; // Clear the input
      this.objectCategorySelectedValue = "";
      this.objectCategoryFilteredOptions = this.objectCaseCategoryOptions; // Reset filtered options
      this.objectCategoryPlaceholderText = "Search and select";
    }
    //clear the subcategory as well
    this.clearSubCategoryInput();
  }

  clearSubCategoryInput() {
    console.log("this.subCaseCategoryOptions : " + this.subCaseCategoryOptions);
    this.subCategoryFilteredOptions = this.subCaseCategoryOptions;
    this.subCategorySearchKey = ""; // Clear the input
    this.subCategorySelectedValue = "";
    /*if (!this.isMaintenance) {
      this.objectCategoryFilteredOptions = this.objectCaseCategoryOptions;
      this.objectCategorySearchKey = "";
      this.objectCategoryPlaceholderText = "Search and select";
    }*/
    this.subCategoryPlaceholderText = "Search and select";
    this.chosenCompanyName = "";
    this.isKhidmah = false;
  }
  clearSubCategoryInputNoReq() {
    console.log("this.subCaseCategoryOptions : " + this.subCaseCategoryOptions);
    this.subCategoryFilteredOptions = this.subCaseCategoryOptions;
    this.subCategorySearchKey = "";
    this.subCategoryPlaceholderText = "";
    this.chosenCompanyName = "";
    this.isKhidmah = false;
  }
  clearobjectCategoryInput() {
    this.objectCategorySearchKey = ""; // Clear the input
    this.objectCategorySelectedValue = "";
    this.objectCategoryFilteredOptions = this.objectCaseCategoryOptions; // Reset filtered options
    this.objectCategoryPlaceholderText = "Search and select";
    if (!this.isMaintenance) {
      this.subcategoryPlaceholderText = "Search and select";
      this.subCategorySearchKey = "";
      this.subCategoryFilteredOptions = this.subCaseCategoryOptions;
    }
  }

  clearCaseOriginInput() {
    this.caseOriginSearchKey = ""; // Clear the input
    this.caseOriginFilteredOptions = this.caseOriginOptions; // Reset filtered options
    this.caseOriginPlaceholderText = "Search and select";
  }
  clearaccountTypeInput() {
    this.accountTypeSearchKey = ""; // Clear the input
    this.accountTypeFilteredOptions = this.accountTypeOptions; // Reset filtered options
    this.accountTypePlaceholderText = "Search and select";
    this.accountTypeSelectedLabel = "";
    this.accountIsPerson = false;
    this.accountIsComp = false;
    this.isPerson = false;
    this.accName = "";
    this.accRegisNo = "";
    this.accPasspNo = "";
    this.accEmiratesId = "";
    this.accEmail = "";
    this.countryCode = "";
    this.mobilePhone = "";
    this.accFirstName = "";
    this.accMiddleName = "";
    this.accLastName = "";
    this.accFloor = "";
    this.accApartmentNumber = "";
    this.packageType = "";
    this.accApartmentNo = "";
    this.accPackageType = "";
    this.accContractNo = "";
    this.accStreetNo = "";
    this.accStreetName = "";
    this.accZipCode = "";
    this.duplicateAccount = false;
    this.duplicateEmailAcc = false;
    this.duplicateEmiratesAcc = false;
    this.duplicatePassportAcc = false;
    this.duplicateMobiletAcc = false;
    this.duplicateRegNo = false;

    this.clearBuildingInput();
  }
  clearCompanyInput() {
    this.companySearchKey = "";
    this.subVerticalDisabled = true;
    // Clear the input
    this.companyFilteredOptions = this.companyOptions; // Reset filtered options
    this.companyPlaceholderText = "Search and select";
    this.companySelectedValue = "";
    this.chosenCompanyName = "";
    this.chosenCompanyId = "";
    this.companyId = "";
    this.clearSubVerticalInput();
    // this.showContracts = false;
  }
  clearContactInput() {
    this.contactSearchKey = ""; // Clear the input
    this.contactFilteredOptions = this.contactoptions; // Reset filtered options
    this.contactPlaceholderText = "Search and select";
  }
  clearBuildingInput() {
    this.buildingSearchKey = ""; // Clear the input
    this.accBuildingFilteredOptions = this.accbuildingOptions; // Reset filtered options
    this.buildingPlaceholderText = "Search and select";

    this.clearAssetInput();
  }
  clearAssetInput() {
    this.unitsAvailable = true;
    this.assetSearchKey = ""; // Clear the input
    this.accAssetFilteredOptions = this.accAssetOptions; // Reset filtered options
    this.unitId = "";
    this.assetPlaceholderText = "Search and select";
    refreshApex(this.wiredKhidmahContracts);
    console.log("after the getKhidmah Wire");
  }

  handleRowContractSelection(event) {
    this.contractDetails = [];
    const selectedRows = event.detail.selectedRows;
    if (selectedRows.length > 0) {
      this.selectedContractId = selectedRows[0].Id;
      this.selectedContract = selectedRows[0];
      console.log("xTx", selectedRows[0]);
      this.contrAccName = selectedRows[0].Account.Name;
      this.contrAccHREF += selectedRows[0].AccountId;
      this.contrAccHREF += "/view";
      if (selectedRows[0].Unit_Contracts__r) {
        this.contractDetails = selectedRows[0].Unit_Contracts__r;
        console.log("available contract details:" + this.contractDetails);
        console.log("contract details size" + this.contractDetails.length);
        this.preSelectedContractDetails = [];
        //console.log('DETAILS',this.contractDetails );
        if (this.contractDetails.length >= 1) {
          const preSelectDetail = [];
          preSelectDetail.push(this.contractDetails[0].Id);
          this.preSelectedContractDetails = preSelectDetail;
          this.selectedContractDetailId = this.contractDetails[0].Id;
        }
      }
    }
    //console.log(this.selectedContractId);
  }

  handleRowContractDetailSelection(event) {
    const selectedRows = event.detail.selectedRows;
    if (selectedRows.length > 0) {
      this.selectedContractDetailId = selectedRows[0].Id;
      const skipCheckbox = this.template.querySelector(
        '[data-id="skipSelection"]'
      );
      console.log("skip", skipCheckbox);
      if (skipCheckbox) {
        skipCheckbox.checked = false;
      }
    }
  }
  handleFCRcheck(event) {
    this.isfcr = event.target.checked;
  }
  handleContractClaimNewAcc(event) {
    this.customerClaimedExistingContract = event.target.checked;
  }
  handleNoContractRadioChange(event) {
    this.selectedProceedNoContract = event.detail.value;
    if (this.selectedProceedNoContract === "newContract") {
      this.createNewContractRequest = true;
      this.preSelectedContractsNoCallOut = [];
      if (this.khidmahUnitContractsNoCallouts.length === 1) {
        const preSelect = [];
        preSelect.push(this.khidmahUnitContractsNoCallouts[0].Id);
        //console.log('DATATABLE',data[0].Id);
        this.preSelectedContractsNoCallout = preSelect;
        this.selectedContractNoCallOut = this.khidmahUnitContractsNoCallouts[0];
        this.selectedContractNoCalloutId =
          this.khidmahUnitContractsNoCallouts[0].Id;
      }
    } else {
      this.createNewContractRequest = false;
      if (this.selectedProceedNoContract == "existingContractClaim") {
        console.log("In the claimed contract");
        this.customerClaimedExistingContract = true;
        console.log(
          "In the claimed contract+ " + this.customerClaimedExistingContract
        );
      }
    }
  }
  async handleChange(event) {
    let name = event.target.name;
    let val = event.target.value;
    if (name == "contactFirstName") {
      this.contactFirstName = val;
      this.duplicateContact = await this.handleContactDuplicateCheck();
    }
    if (name == "contactLastName") {
      this.contactLastName = val;
      this.duplicateContact = await this.handleContactDuplicateCheck();
    }
    if (name == "contactMobileCountry") {
      console.log("entered here:" + this.contactMobileCountry);
      this.contactMobileCountry = val;
      this.duplicateContact = await this.handleContactDuplicateCheck();
    }
    if (name == "contactEmail") {
      this.contactEmail = val;
    }
    if (name == "contactCountryCode") {
      this.contactCountryCode = val;
    }
    if (name == "CustomerType") {
      this.customerTypeVal = val;
    }
    if (name == "country") {
      this.countryValue = val;
    }

    if (name == "salutation") {
      this.salutationValue = val;
    }
    if (name == "nationality") {
      this.nationalityValue = val;
    }

    if (name == "contractCtreationSelect") {
      console.log("val:" + event.target.checked);
      this.contractCreationReq = event.target.checked;
      this.showContracts = !event.target.checked;
    }
    if (name == "startDate") {
      this.contractStartDate = val;
    } else if (name == "endDate") {
      this.contractEndDate = val;
    } else if (name == "KhidmahContractType") {
      this.selectedContractType = val;
    } else if (name == "numCallOuts") {
      this.numberOfCallOuts = val;
    } else if (name == "description") {
      this.description = val;
    } else if (name == "skipDetailSelection") {
      this.skipDetailsSelection = event.target.checked;
      if (this.skipDetailsSelection) {
        console.log("IN");
        const datatable = this.template.querySelector(
          '[data-id="contractDetailDataTable"]'
        );
        console.log("tt", datatable);
        if (datatable) {
          console.log("Table");

          datatable.selectedRows = [];
        }
      }
    } else if (name == "reprogramming") {
      this.isReprogramming = event.target.checked;
    } else if (name == "New/additional Card") {
      this.isNewAdditionalCard = event.target.checked;
    } else if (name == "Replacement") {
      this.isReplacement = event.target.checked;
    }
  }

  handleCustomerTypeToggleDropdown(event) {
    if (this.companyDropdownVisible) this.companyDropdownVisible = false;
    if (this.subVerticalDropdownVisible)
      this.subVerticalDropdownVisible = false;
    if (this.objectCategoryDropdownVisible)
      this.objectCategoryDropdownVisible = false;
    if (this.subCategoryDropdownVisible)
      this.subCategoryDropdownVisible = false;
    if (this.caseTypeDropdownVisible) this.caseTypeDropdownVisible = false;
    if (this.caseOriginDropdownVisible) this.caseOriginDropdownVisible = false;
    if (this.categoryDropdownVisible) this.categoryDropdownVisible = false;
  }
  showToast(title, message, variant) {
    this.isLoading = false;
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }
  handleError(error) {
    let fieldErrors = [];
    if (
      error.body &&
      error.body.output &&
      JSON.stringify(error.body.output.fieldErrors) !== "{}"
    ) {
      fieldErrors = Object.values(error.body.output.fieldErrors).flat();
      this.errorMessages = fieldErrors.map((err) => err.message);
    } else if (
      error.body &&
      error.body.output &&
      JSON.stringify(error.body.output.errors) !== "{}"
    ) {
      fieldErrors = Object.values(error.body.output.errors).flat();
      this.errorMessages = fieldErrors.map((err) => err.message);
    }

    this.showToast(
      "Error",
      "Failed to Update Record: " + JSON.stringify(this.errorMessages),
      "error"
    );
  }
  async handleCreateCase() {
    const fields = {};
    console.log("accountSelectedRecordInput:");
    console.log("nextline:" + this.accountSelectedRecordInput);
    if (
      !(
        this.accountCreationCheckbox ||
        (this.accountSelectedRecordInput != "" &&
          this.accountSelectedRecordInput != null) ||
        this.accountId != ""
      )
    ) {
      this.showToast(
        "Error",
        "You have to fill in the customer values ",
        "error"
      );
      return;
    }

    fields[Description.fieldApiName] = this.description;
    fields[ECSS_CaseCustomerType.fieldApiName] = this.customerTypeVal;
    fields[ECSS_Created_From_Component.fieldApiName] = true;
    fields[recordType.fieldApiName] = this.caseTypeSelectedValue;
    fields[ECSS_CASE_SUB_CATEGORY.fieldApiName] = this.subCategorySelectedValue;
    fields[ECSS_CASE_OBJECT_CATEGORY.fieldApiName] =
      this.objectCategorySelectedValue;
    fields[caseCategory.fieldApiName] = this.categorySelectedValue;
    fields[subVertical.fieldApiName] = this.subVerticalSelectedValue;
    fields[FCR.fieldApiName] = this.isfcr;
    // fields[caseSubject.fieldApiName] = this.subject;
    fields[caseOrigin.fieldApiName] = this.caseOriginSelectedValue;
    console.log('ContactId value: ' + this.contactId);
    fields[ECSS_contactId.fieldApiName] = this.contactId;
    fields[ECSS_NewContactRelationship.fieldApiName] =
      this.contactRelatedCmpValueId;
    fields[ECSS_contactIdSelected.fieldApiName] = this.contactSelectedValue;

    //console.log('Test'+this.ecssUnitId +'COmp'+this.companyId);
    fields[ECSS_UNIT.fieldApiName] = this.unitId;
    fields[ECSS_Company.fieldApiName] = this.companySelectedValue;
    if (this.cAccountId == '' || this.cAccountId == null)
      fields[ECSS_Account.fieldApiName] = this.accountId;
    else
      fields[ECSS_Account.fieldApiName] = this.cAccountId;

    fields[ECSS_EmergencyCase.fieldApiName] = this.isEmrgencyCase;
    fields[ECSS_ReprogrammingNeeded.fieldApiName] = this.isReprogramming;
    fields[ECSS_NewAdditionalCardNeeded.fieldApiName] =
      this.isNewAdditionalCard;
    fields[ECSS_Replacement.fieldApiName] = this.isReplacement;
    fields[ECSS_AccountCreationType.fieldApiName] =
      this.accountTypeSelectedLabel;
    //cotact details
    fields[ECSS_NewContactCountryCode.fieldApiName] = this.contactCountryCode;
    if(this.contactMobileCountry != null && this.contactMobileCountry != '' && this.contactMobileCountry != undefined){
      if (this.contactMobileCountry.startsWith('0')) {
          this.contactMobileCountry = this.contactMobileCountry.substring(1);
      }
    }
    fields[ECSS_NewContactMobileNumber.fieldApiName] =
      this.contactMobileCountry;
    fields[NewContactLastName.fieldApiName] = this.contactLastName;
    fields[NewContactFirstName.fieldApiName] = this.contactFirstName;
    fields[NewContactEmail.fieldApiName] = this.contactEmail;

    //new account creation request
    if (this.accountId == "") {
      fields[ECSS_NonExistingCustomerApprovalPending.fieldApiName] = true;
    }
    fields[ECSS_RequestedAccountName.fieldApiName] = this.accName;
    fields[ECSS_RequestedRegistractionNumber.fieldApiName] = this.accRegisNo;
    fields[ECSS_RequestedEmiratesId.fieldApiName] = this.accEmiratesId;
    fields[ECSS_RequestedPassportNo.fieldApiName] = this.accPasspNo;
    fields[ECSS_RequestedEmail.fieldApiName] = this.accEmail;
    fields[ECSS_RequestedMobileCountryCode.fieldApiName] = this.countryCode;
    
    if(this.mobilePhone != null && this.mobilePhone != '' && this.mobilePhone != undefined){
      if (this.mobilePhone.startsWith('0')) {
          this.mobilePhone = this.mobilePhone.substring(1);
      }
    }
    fields[ECSS_RequestedMobileNumber.fieldApiName] = this.mobilePhone;
    fields[ECSS_Req_Acc_Type.fieldApiName] = this.accountTypeSelectedLabel;
    fields[ECSS_ZipCode__c.fieldApiName] = this.accZipCode;
    fields[ECSS_AccountStreetName.fieldApiName] = this.accStreetName;
    fields[ECSS_AccountStreeNo.fieldApiName] = this.accStreetNo;
    fields[ECSS_ApartmentNumber.fieldApiName] = this.accApartmentNo;
    fields[ECSS_AccountBuildingSection.fieldApiName] =
      this.buildingSelectedValue;
    fields[ECSS_AccountFirstName.fieldApiName] = this.accFirstName;
    fields[ECSS_AccountMiddleName.fieldApiName] = this.accMiddleName;
    fields[ECSS_AccountLastName.fieldApiName] = this.accLastName;
    fields[ECSS_Floor.fieldApiName] = this.accFloor;
    fields[ECSS_AccountUnit.fieldApiName] = this.assetSelectedValue;
    fields[ECSS_PackageType.fieldApiName] = this.accPackageType;
    fields[ECSS_ContractReceiptNumber.fieldApiName] = this.accContractNo;
    fields[ECSS_AccountSalutation.fieldApiName] = this.salutationValue;
    fields[ECSS_AccountCountry.fieldApiName] = this.countryValue;
    fields[ECSS_AccountNationality.fieldApiName] = this.nationalityValue;
    // fields[ECSS_CreateAccount.fieldApiName] = !this.customerClaimedExistingContract && this.accountCreationCheckbox;
    fields[ECSS_CreateAccount.fieldApiName] = this.accountCreationCheckbox;
    console.log("this.parentCaseId:" + this.parentCaseId);
    if (this.accountCreationCheckbox && this.isMaintenance) {
      fields[ECSS_Account_Contract_Request.fieldApiName] = true;
    }
    if (this.parentCaseId != "") {
      console.log("this.parentCaseId:" + this.parentCaseId);
      fields[ECSparentCaseId.fieldApiName] = this.parentCaseId;
    }

    if (this.mobilePhone !== "") {
      const isPhoneValid = await this.handlePhoneValidaty();
      if (!isPhoneValid) {
        return; // Stop execution if phone is invalid
      }
    }

    if (this.contactMobileCountry != "") {
      this.handleContactPhoneValidaty();
      if (this.contactPhoneInvalid) {
        return;
      }
    }

    //////VALIDATIONS////////////////
    //Generic required fields missing
    if (this.accountCreationCheckbox && this.newAccContractExists) {
      if (this.selectedContract != null) {
        this.handleGetAccount();
        this.customerClaimedExistingContract = false;
        this.accountCreationCheckbox = false;
        this.accName = "";
        this.accRegisNo = "";
        this.accEmiratesId = "";
        this.accPasspNo = "";
        this.accEmail = "";
        this.countryCode = "";
        this.mobilePhone = "";
        this.accZipCod = "";
        this.accStreetName = "";
        this.accStreetNo = "";
        this.accApartmentNo = "";
        this.buildingSelectedValue = "";
        this.accFirstName = "";
        this.accMiddleName = "";
        this.accLastName = "";
        this.accFloor = "";
        this.assetSelectedValue = "";
        this.accPackageType = "";
      }
      this.showToast(
        "Error",
        "There are active Contracts on this unit, which means this account exists on the system, kindly double check",
        "error"
      );
      return;
    }

    if (
      this.assetAccExists &&
      this.contactSelectedValue == "" &&
      !this.contactCreationCheckbox &&
      !this.isPerson
    ) {
      this.showToast(
        "Error",
        "You have to fill in the Contact values ",
        "error"
      );
      return;
    }
    if (
      this.assetAccExists &&
      this.contactSelectedValue == "" &&
      !this.contactCreationCheckbox &&
      this.isPerson &&
      !this.mainContactUseage &&
      this.contactId == ""
    ) {
      this.showToast(
        "Error",
        "You have to either use the main account or fill in the Contact values ",
        "error"
      );
      return;
    }
    if (this.contactCreationCheckbox && this.contactFirstName == "") {
      this.showToast(
        "Error",
        "You have to fill in the Contact First Name ",
        "error"
      );
      return;
    }
    if (this.contactCreationCheckbox && this.contactLastName == "") {
      this.showToast(
        "Error",
        "You have to fill in the Contact Last Name ",
        "error"
      );
      return;
    }
    /* if (this.contactCreationCheckbox && this.contactEmail == "") {
      this.showToast(
        "Error",
        "You have to fill in the Contact Email ",
        "error"
      );
      return;
    }
    */
    if (this.contactCreationCheckbox && this.contactMobileCountry == "") {
      this.showToast(
        "Error",
        "You have to fill in the Contact Mobile Number ",
        "error"
      );
      return;
    }
    if (this.contactCreationCheckbox && this.contactCountryCode == "") {
      this.showToast(
        "Error",
        "You have to fill in the Contact Country Code ",
        "error"
      );
      return;
    }
    if (
      this.accountIsComp &&
      !this.recordId &&
      this.accRegisNo == "" &&
      this.accountCreationCheckbox
    ) {
      this.showToast(
        "Error",
        "You have to fill in the Registration Number ",
        "error"
      );
      return;
    }
    if (
      !this.accountIsPerson &&
      !this.recordId &&
      this.countryValue == "" &&
      this.accountCreationCheckbox &&
      (this.accountId == "" || this.accountId == null)
    ) {
      this.showToast("Error", "You have to fill in the Country ", "error");
      return;
    }

    if (
      this.accountIsPerson &&
      !this.recordId &&
      this.salutationValue == "" &&
      this.accountCreationCheckbox
    ) {
      this.showToast("Error", "You have to fill in the Salutation ", "error");
      return;
    }

    if (
      !this.recordId &&
      this.mobilePhone == "" &&
      this.accountCreationCheckbox
    ) {
      this.showToast("Error", "You have to fill in the Mobile Number", "error");
      return;
    }

    if (
      this.accountIsPerson &&
      !this.recordId &&
      this.accFirstName == "" &&
      this.accountCreationCheckbox
    ) {
      this.showToast("Error", "You have to fill in the First Name", "error");
      return;
    }
    if (
      this.accountIsPerson &&
      !this.recordId &&
      this.accLastName == "" &&
      this.accountCreationCheckbox
    ) {
      this.showToast("Error", "You have to fill in the Last Name", "error");
      return;
    }
    if (
      this.accountIsPerson &&
      !this.recordId &&
      this.accFloor == "" &&
      this.accountCreationCheckbox
    ) {
      this.showToast("Error", "You have to fill in the floor", "error");
      return;
    }
    if (!this.recordId && this.accEmail == "" && this.accountCreationCheckbox) {
      this.showToast("Error", "You have to fill in the Email", "error");
      return;
    }
    if (
      !this.accountIsPerson &&
      !this.recordId &&
      this.accName == "" &&
      this.accountCreationCheckbox
    ) {
      this.showToast("Error", "You have to fill in the Account Name", "error");
      return;
    }

    if (!this.recordId && this.unitId == "" && this.accountCreationCheckbox) {
      this.showToast("Error", "You have to fill in the Unit ", "error");
      return;
    }

    if (this.companySelectedValue == "") {
      this.showToast(
        "Error",
        'Selecting a "Company" is mandatory to proceed',
        "error"
      );
      return;
    }
    /*   if(this.subject ==''){
               this.showToast('Error', 'Entering a "Subject" is mandatory to proceed', 'error');
               return; 
           }*/
    if (this.description == "") {
      this.showToast(
        "Error",
        'Entering a "Description" is mandatory to proceed',
        "error"
      );
      return;
    }
    if (this.customerTypeVal == "") {
      this.showToast(
        "Error",
        'Entering a "Customer Type" is mandatory to proceed',
        "error"
      );
      return;
    }
    if (this.categorySelectedValue == "") {
      this.showToast(
        "Error",
        'Entering an "Incident Category" is mandatory to proceed',
        "error"
      );
      return;
    }
    if (this.subCategorySelectedValue == "") {
      this.showToast(
        "Error",
        'Entering a "Cause Category" is mandatory to proceed',
        "error"
      );
      return;
    }
    if (this.objectCategorySelectedValue == "") {
      this.showToast(
        "Error",
        'Entering an "Object Category" is mandatory to proceed',
        "error"
      );
      return;
    }

    if (this.caseOriginSelectedValue == "") {
      this.showToast(
        "Error",
        'Entering an "Origin" is mandatory to proceed',
        "error"
      );
      return;
    }
    if (this.contactPhoneInvalid) {
      this.showToast(
        "Error",
        "Invalid contact phone number format. Please ensure the phone number matches the standard format for the selected country !",
        "error"
      );
      return;
    }
    if (this.contactCreationCheckbox && this.duplicateContact) {
      this.showToast(
        "Error",
        "This Contact already exists with similar values",
        "error"
      );
      //return;

    }
    if (
      this.accountIsPerson &&
      (this.duplicateEmailAcc ||
        this.duplicateEmiratesAcc ||
        this.duplicateMobiletAcc ||
        this.duplicatePassportAcc)
    ) {
      console.log("duplicateCheck : entered the duplication");
      this.showToast(
        "Error",
        "This Account already exists with similar values",
        "error"
      );
      return;
    }
    if (this.accountIsComp && this.duplicateRegNo) {
      console.log("duplicateCheck : entered the duplication");
      this.showToast(
        "Error",
        "This Account already exists with similar values",
        "error"
      );
      return;
    }

    if (this.companyWrapMap.has(this.companyId)) {
      // to check if selected company matches the selected Cat/Sub Category
      let key =
        this.categorySelectedValue + "|" + this.subCategorySelectedValue;
      if (this.catSubCatEltizamMap.has(key)) {
        if (
          (!this.companyWrapMap.get(this.companyId).isEltizamCompany &&
            this.catSubCatEltizamMap.get(key)) ||
          (this.companyWrapMap.get(this.companyId).isEltizamCompany &&
            !this.catSubCatEltizamMap.get(key))
        ) {
          console.log("error");
          this.showToast(
            "Error",
            "Selected Company does not match the selected catogery and sub category",
            "error"
          );
          return;
        }
      }
    }

    if (this.contactPhoneInvalid) {
      console.log("in the pgone invalid");
      this.showToast(
        "Error",
        "Invalid contact phone number format. Please ensure the phone number matches the standard format for the selected country !",
        "error"
      );
      return;
    }

    //console.log('ddd'+this.selectedOption+'KHIDM'+this.isKhidmah);
    if (
      this.isKhidmah ||
      (!this.isKhidmah &&
        (this.caseTypeSearchKey.includes("Maintenance") ||
          this.caseTypeSearchKey.includes("Request")) &&
        !this.newAccContractExists)
    ) {
      if (!this.selectedContractId && this.khidmahUnitContracts.length) {
        // if there are khidmah contracts but the user didn't select any
        this.showToast("Error", "Please select Contract", "error");
        return;
      }
      if (
        !this.khidmahUnitContracts.length &&
        !this.selectedProceedNoContract &&
        !this.contractCreationReq &&
        !this.accountCreationCheckbox
      ) {
        // if there are no khidmah contracts and user didn't select how to proceed
        this.showToast("Error", "Please choose how to proceed", "error");
        return;
      } else if (
        !this.khidmahUnitContracts.length &&
        this.selectedProceedNoContract
      ) {
        /*if(this.createNewContractRequest)
                {
                    fields[ECSS_CONTRACT_START.fieldApiName] = this.contractStartDate;
                    fields[ECSS_CONTRACT_END.fieldApiName] = this.contractEndDate;
                    fields[ECSS_NUM_CALLOUTS.fieldApiName] = this.numberOfCallOuts;
                    fields[ECSS_KHIDMAH_CONT_TYPES.fieldApiName] = this.selectedContractType;
                    let recTypeKhidma = Object.keys(this.recordTypeIds).find(recordTypeId => this.recordTypeIds[recordTypeId].name === 'ECSS Khidmah Contract Request');
                    fields[RecordTypeId.fieldApiName]= recTypeKhidma;
                    //console.log('REC',recTypeKhidma);
                    if(this.contractStartDate ==  null || this.contractEndDate == null)
                    {
                        this.showToast('Error', 'Please select Contract Start and End Date!', 'error');
                        return;
                    }
                    if(this.contractStartDate !=  null && this.contractEndDate != null && this.contractEndDate< this.contractStartDate )
                    {
                        this.showToast('Error', 'Contract Start Date should be earlier than Contract End Date !', 'error');
                        return;
                    }
                    
                    if(this.selectedContractType ==  null)
                    {
                        this.showToast('Error', 'Please select Khidmah Contract Type!', 'error');
                        return;
                    }
                }*/
      }
      if (this.selectedContractNoCallOut != null) {
        fields[ECSS_Top_Up_Contract.fieldApiName] =
          this.selectedContractNoCalloutId;
        fields[ECSS_isCaseApproved.fieldApiName] = false;
      }
      if (this.selectedContractId) {
        // if user selected a khidmah contract
        fields[ECSS_CONTRACT.fieldApiName] = this.selectedContractId;

        if (this.contractDetails.length) {
          // if there are contract details and user didn't select a detail or skipped selection
          console.log("SKIP", this.skipDetailsSelection);
          if (
            !this.selectedContractDetailId &&
            !this.skipDetailsSelection &&
            this.selectedContractId
          ) {
            this.showToast(
              "Error",
              'Please select one of the Contract Details or mark "Skip Details Selection" as true',
              "error"
            );
            return;
          } else {
            if (this.skipDetailsSelection) {
              fields[ECSS_CONTRACT_DETAILS_SELECTION_SKIPPED.fieldApiName] =
                true;
            }
            if (this.selectedContractDetailId) {
              fields[ECSS_CONTRACT_DETAILS_ID.fieldApiName] =
                this.selectedContractDetailId;
            }
          }
        }
      }
    }

    if (this.createNewContractRequest) {
      // if new request selected
      fields[ECSS_CONTRACT_START.fieldApiName] = this.contractStartDate;
      fields[ECSS_CONTRACT_END.fieldApiName] = this.contractEndDate;
      fields[ECSS_NUM_CALLOUTS.fieldApiName] = this.numberOfCallOuts;
      fields[ECSS_KHIDMAH_CONT_TYPES.fieldApiName] = this.selectedContractType;
      console.log("before recordtype");
      let khidmahRecord = this.caseRecordTypes.find((recordType) =>
        recordType.label.includes("Khidmah")
      );

      let recTypeKhidma = khidmahRecord ? khidmahRecord.value : null;

      //fields[recordType.fieldApiName]= recTypeKhidma;
      /*  if(this.contractStartDate ==  null || this.contractEndDate == null)
              {
                  this.showToast('Error', 'Please select Contract Start and End Date!', 'error');
                  return;
              }
              if(this.contractStartDate !=  null && this.contractEndDate != null && this.contractEndDate< this.contractStartDate )
              {
                  this.showToast('Error', 'Contract Start Date should be earlier than Contract End Date !', 'error');
                  return;
              }*/
      /*if(this.numberOfCallOuts ==  null)
            {
                this.showToast('Error', 'Please select Number of Call Outs!', 'error');
                return;
            }*/
      /* if(this.selectedContractType ==  null)
             {
                 this.showToast('Error', 'Please select Khidmah Contract Type!', 'error');
                 return;
             }*/
    }

    // Create the case record
    const caseRecord = {
      apiName: "case",
      fields: fields
    };
    this.isLoading = true;
    console.log("case tobe ceated:", JSON.stringify(caseRecord));

    createRecord(caseRecord)
      .then((result) => {
        this.isLoading = false;
        insertDocuments({
          contentDocIds: this.uploadDocIds,
          recId: result.id
        }).then((data) => {
          console.log("Success");
        });

        console.log("in the created case");
        this.clearCaseTypeInput();
        this.showToast("Success", "Case created successfully!", "success");
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: result.id,
            objectApiName: "Case",
            actionName: "view"
          }
        });
      })
      .catch((error) => {
        if (error) {
          console.log("err", error);
          if(error != null && error.body != null && error.body.output != null && error.body.output.errors!= null && error.body.output.errors.length >0 ){
            this.showToast("Error", error.body.output.errors[0].message, "error");
          }
          console.log("err String", JSON.stringify(error));
          this.isLoading = false;
        }
      });
  }

  handleEditCase() {
    const fields = {};
    fields[Description.fieldApiName] = this.description;
    fields[caseRecId.fieldApiName] = this.caseId;
    fields[ECSS_Created_From_Component.fieldApiName] = true;
    fields[ECSS_CASE_OBJECT_CATEGORY.fieldApiName] =
      this.objectCategorySelectedValue;
    fields[recordType.fieldApiName] = this.caseTypeSelectedValue;
    fields[subCategory.fieldApiName] = this.subCategorySelectedValue;
    fields[subVertical.fieldApiName] = this.subVerticalSelectedValue;
    fields[caseCategory.fieldApiName] = this.categorySelectedValue;
    //fields[caseSubject.fieldApiName] = this.subject;
    fields[caseOrigin.fieldApiName] = this.caseOriginSelectedValue;
    fields[ECSS_contactId.fieldApiName] = this.contactId;
    fields[ECSS_NewContactRelationship.fieldApiName] =
      this.contactRelatedCmpValueId;
    fields[ECSS_contactIdSelected.fieldApiName] = this.contactSelectedValue;
    fields[ECSS_Status.fieldApiName]= 'In Progress';
    console.log('contactId : ' + this.contactId);
    //console.log('Test'+this.ecssUnitId +'COmp'+this.companyId);
    fields[ECSS_UNIT.fieldApiName] = this.unitId;
    fields[ECSS_Company.fieldApiName] = this.companySelectedValue;
    if (this.cAccountId == '' || this.cAccountId == null)
      fields[ECSS_Account.fieldApiName] = this.accountId;
    else
      fields[ECSS_Account.fieldApiName] = this.cAccountId;
    fields[ECSS_EmergencyCase.fieldApiName] = this.isEmrgencyCase;
    fields[ECSS_ReprogrammingNeeded.fieldApiName] = this.isReprogramming;
    fields[ECSS_NewAdditionalCardNeeded.fieldApiName] =
      this.isNewAdditionalCard;
    fields[ECSS_contactIdSelected.fieldApiName] = this.contactSelectedValue;

    fields[ECSS_Replacement.fieldApiName] = this.isReplacement;
    console.log("this.parentCaseId:" + this.parentCaseId);
    if (this.parentCaseId != "") {
      console.log("this.parentCaseId:" + this.parentCaseId);
      fields[ECSparentCaseId.fieldApiName] = this.parentCaseId;
    }

    //new account creation request
    if (this.accountId == "") {
      fields[ECSS_NonExistingCustomerApprovalPending.fieldApiName] = true;
    }
    fields[ECSS_RequestedAccountName.fieldApiName] = this.accName;
    fields[ECSS_RequestedRegistractionNumber.fieldApiName] = this.accRegisNo;
    fields[ECSS_RequestedEmiratesId.fieldApiName] = this.accEmiratesId;
    fields[ECSS_RequestedPassportNo.fieldApiName] = this.accPasspNo;
    fields[ECSS_RequestedEmail.fieldApiName] = this.accEmail;
    fields[ECSS_RequestedMobileCountryCode.fieldApiName] = this.countryCode;
    fields[ECSS_RequestedMobileNumber.fieldApiName] = this.mobilePhone;
    fields[ECSS_NewContactCountryCode.fieldApiName] = this.contactCountryCode;
    fields[ECSS_NewContactMobileNumber.fieldApiName] =
      this.contactMobileCountry;
    fields[NewContactLastName.fieldApiName] = this.contactLastName;
    fields[NewContactFirstName.fieldApiName] = this.contactFirstName;
    fields[NewContactEmail.fieldApiName] = this.contactEmail;

    if (this.mobilePhone != "") {
      this.handlePhoneValidaty();
      if (this.contactPhoneInvalid) {
        return;
      }
    }
    console.log("reached before validations");

    //////VALIDATIONS////////////////
    //Generic required fields missing
    if (this.companySelectedValue == "") {
      this.showToast(
        "Error",
        'Selecting a "Company" is mandatory to proceed',
        "error"
      );
      return;
    }
    /*if(this.subject ==''){
            this.showToast('Error', 'Entering a "Subject" is mandatory to proceed', 'error');
            return; 
        }*/
    if (this.description == "") {
      this.showToast(
        "Error",
        'Entering a "Description" is mandatory to proceed',
        "error"
      );
      return;
    }
    if (this.companyWrapMap.has(this.companyId)) {
      // to check if selected company matches the selected Cat/Sub Category
      let key =
        this.categorySelectedValue + "|" + this.subCategorySelectedValue;
      if (this.catSubCatEltizamMap.has(key)) {
        /*if((!this.companyWrapMap.get(this.companyId).isEltizamCompany && this.catSubCatEltizamMap.get(key)) || (this.companyWrapMap.get(this.companyId).isEltizamCompany && !this.catSubCatEltizamMap.get(key)))
                {   console.log('error');
                    this.showToast('Error', 'Selected Company does not match the selected catogery and sub category', 'error');
                    return; 
                }*/
      }
    }

    //console.log('ddd'+this.selectedOption+'KHIDM'+this.isKhidmah);
    if (
      this.isKhidmah ||
      (!this.isKhidmah && this.selectedOption === "Maintenance") ||
      this.selectedOption === "Request"
    ) {
      if (!this.selectedContractId && this.khidmahUnitContracts.length) {
        // if there are khidmah contracts but the user didn't select any
        this.showToast("Error", "Please select Khidmah Contract", "error");
        return;
      }
      if (
        !this.khidmahUnitContracts.length &&
        !this.selectedProceedNoContract
      ) {
        // if there are no khidmah contracts and user didn't select how to proceed
        this.showToast("Error", "Please choose how to proceed", "error");
        return;
      } else if (
        !this.khidmahUnitContracts.length &&
        this.selectedProceedNoContract
      ) {
        /*if(this.createNewContractRequest)
                {
                    fields[ECSS_CONTRACT_START.fieldApiName] = this.contractStartDate;
                    fields[ECSS_CONTRACT_END.fieldApiName] = this.contractEndDate;
                    fields[ECSS_NUM_CALLOUTS.fieldApiName] = this.numberOfCallOuts;
                    fields[ECSS_KHIDMAH_CONT_TYPES.fieldApiName] = this.selectedContractType;
                    let recTypeKhidma = Object.keys(this.recordTypeIds).find(recordTypeId => this.recordTypeIds[recordTypeId].name === 'ECSS Khidmah Contract Request');
                    fields[RecordTypeId.fieldApiName]= recTypeKhidma;
                    //console.log('REC',recTypeKhidma);
                    if(this.contractStartDate ==  null || this.contractEndDate == null)
                    {
                        this.showToast('Error', 'Please select Contract Start and End Date!', 'error');
                        return;
                    }
                    if(this.contractStartDate !=  null && this.contractEndDate != null && this.contractEndDate< this.contractStartDate )
                    {
                        this.showToast('Error', 'Contract Start Date should be earlier than Contract End Date !', 'error');
                        return;
                    }
                    
                    if(this.selectedContractType ==  null)
                    {
                        this.showToast('Error', 'Please select Khidmah Contract Type!', 'error');
                        return;
                    }
                }*/
      }

      if (this.selectedContractId) {
        // if user selected a khidmah contract
        fields[ECSS_CONTRACT.fieldApiName] = this.selectedContractId;

        if (this.contractDetails.length) {
          // if there are contract details and user didn't select a detail or skipped selection
          console.log("SKIP", this.skipDetailsSelection);
          console.log("this.selectedContracId" + this.selectedContracId);
          if (
            !this.selectedContractDetailId &&
            !this.skipDetailsSelection &&
            this.selectedContracId
          ) {
            this.showToast(
              "Error",
              'Please select one of the Contract Details or mark "Skip Details Selection" as true',
              "error"
            );
            return;
          } else {
            if (this.skipDetailsSelection) {
              fields[ECSS_CONTRACT_DETAILS_SELECTION_SKIPPED.fieldApiName] =
                true;
            }
            if (this.selectedContractDetailId) {
              fields[ECSS_CONTRACT_DETAILS_ID.fieldApiName] =
                this.selectedContractDetailId;
            }
          }
        }
      }
    }
    if (this.createNewContractRequest) {
      // if new request selected
      fields[ECSS_CONTRACT_START.fieldApiName] = this.contractStartDate;
      fields[ECSS_CONTRACT_END.fieldApiName] = this.contractEndDate;
      fields[ECSS_NUM_CALLOUTS.fieldApiName] = this.numberOfCallOuts;
      fields[ECSS_KHIDMAH_CONT_TYPES.fieldApiName] = this.selectedContractType;
      let recTypeKhidma = Object.keys(this.caseTypeOptions).find(
        (recordTypeId) =>
          this.caseTypeOptions[recordTypeId].name ===
          "ECSS Khidmah Contract Request"
      );
      fields[recordType.fieldApiName] = recTypeKhidma;
      //console.log('REC',recTypeKhidma);
      if (this.contractStartDate == null || this.contractEndDate == null) {
        this.showToast(
          "Error",
          "Please select Contract Start and End Date!",
          "error"
        );
        return;
      }
      if (
        this.contractStartDate != null &&
        this.contractEndDate != null &&
        this.contractEndDate < this.contractStartDate
      ) {
        this.showToast(
          "Error",
          "Contract Start Date should be earlier than Contract End Date !",
          "error"
        );
        return;
      }
      /*if(this.numberOfCallOuts ==  null)
            {
                this.showToast('Error', 'Please select Number of Call Outs!', 'error');
                return;
            }*/
      if (this.selectedContractType == null) {
        this.showToast(
          "Error",
          "Please select Khidmah Contract Type!",
          "error"
        );
        return;
      }
    }
    console.log("Reach before case updat");

    // Create the case record
    const caseRecord = {
      fields: fields
    };
    this.isLoading = true;
    console.log("case tobe ceated:", JSON.stringify(caseRecord));
    updateRecord(caseRecord)
      .then((result) => {
        insertDocuments({
          contentDocIds: this.uploadDocIds,
          recId: this.caseId
        }).then((data) => {
          console.log("Success");
        });

        console.log("in the updated case" + JSON.stringify(result));
        this.showToast("Success", "Case created successfully!", "success");
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: this.caseId,
            objectApiName: "Case",
            actionName: "view"
          }
        });
      })
      .catch((error) => {
        if (error) {
          console.log("err", error);
          console.log("err String", JSON.stringify(error));
          this.isLoading = false;
        }
      });
  }

  //end edit
  handleMouseOver(event) {
    const tooltip = this.template.querySelector(".tooltip");
    const targetElement = event.currentTarget; // The div or target element
    const rect = targetElement.getBoundingClientRect(); // Get the position and dimensions of the target div
    tooltip.style.display = "inline";
    tooltip.style.left = `${rect.left + window.scrollX}px`; // X-position relative to the element
    tooltip.style.top = `${rect.bottom + window.scrollY + 10}px`;
  }
  handleMouseOut() {
    const tooltip = this.template.querySelector(".tooltip");
    tooltip.style.display = "none";
  }
  //method to capture output of the customContactLookupCmp

  handleDataEventContact(event) {
    this.contactRelatedCmpValue = event.detail;
    this.contactRelatedCmpValueId = event.detail.Id;
    this.contactId = event.detail.Id;
    console.log("this.contactRelatedCmpValue:" + this.contactRelatedCmpValue);
    if (this.contactRelatedCmpValue) {
      this.contactSelectionDisabled = true;
    } else {
      this.contactSelectionDisabled = false;
    }
  }
  // Method to capture the output of the customLookupComp
  handleDataEvent(event) {
    console.log('Line 4164', this.unitId);
    console.log("Data received from child:", JSON.stringify(event.detail));
    this.accountId = event.detail.Id;
    this.accountRec = event.detail;
    this.accHREF += event.detail.Id;
    this.accHREF += "/view";
    this.contactSelectionPreview = false;
    this.contactId = "";
    this.contactFilteredOptions = [];
    getRelatedContacts({ accId: this.accountId, assetId: this.unitId })
      .then((result) => {
        console.log("Contactres:" + JSON.stringify(result));
        result.forEach((conta) => {
          this.contactoptions.push({
            label: conta.Name,
            value: conta.Idval
          });
          if (!conta.isPerson) {
            this.contactSelectionPreview = true;
          } else {
            this.isPerson = true;
            this.contactId = conta.Idval;
          }
          this.contactValueMap.set(recordType.value, recordType.label);
        });
        this.contactFilteredOptions = this.contactoptions;
      })
      .catch((error) => {
        console.log("in the contact errr");
        console.log(error);
      });

    refreshApex(this.wiredCustomerUnits);
  }
  handleCheckboxChange(event) {
    let name = event.target.name;
    let val = event.target.value;

    if (name == "contact") {
      this.contactCreationCheckbox = event.target.checked;
      if (this.contactCreationCheckbox) {
        this.mainContactUseage = false;
        this.contactSelectionDisabled = true;
      } else {
        this.contactSelectionDisabled = false;
        this.NewContactFirstName = "";
        this.NewContactLastName = "";
        this.NewContactEmail = "";
        this.contactMobileCountry = "";
        this.contactCountryCode = "";
      }
      if (this.contactCreationCheckbox) {
        if (
          this.accountTypeSelectedValue == "" ||
          this.accountTypeSelectedValue == null
        ) {
          console.log(
            "entered the conditon to fill in the mobilecountry codes"
          );
          const org = "Organization";
          const option = this.accountTypeOptions.find(
            (option) => org.toLowerCase() === org.toLowerCase()
          );
          this.accountTypeSelectedValue = option ? option.value : null;

          refreshApex(this.picklistValuesAccountType);
        }
        this.clearContactInput();
      }
      console.log("entered in the contact checkbox");
    } else if (name == "mainAccContact") {
      this.mainContactUseage = event.target.checked;
      if (this.mainContactUseage) {
        this.contactCreationCheckbox = false;
        this.contactSelectionDisabled = true;
      } else {
        this.contactSelectionDisabled = false;
      }
    } else {
      this.accountCreationCheckbox = event.target.checked;
      console.log("on Checkbox:", this.accountCreationCheckbox);
    }
  }
  handleEmergencyCheckboxChange(event) {
    this.isEmrgencyCase = event.target.checked;
  }
  handleContactPhoneValidaty() {
     var checkPhoneValidaty = true;
     this.contactPhoneInvalid = false;
    if(this.contactMobileCountry != null && this.contactMobileCountry != '' && this.contactMobileCountry != undefined){
       const isValid = (/^05\d{8}$/.test(this.contactMobileCountry) || /^\d{9}$/.test(this.contactMobileCountry));

        if (!isValid) {
          checkPhoneValidaty = false;
          this.contactPhoneInvalid = true;
          this.showToast(
            "Error",
            "Mobile number must be 9 digits or 10 digits starting with '05', with no spaces or special characters.",
            "error"
          );
          return false;
        }
        // Remove leading zero if present
        if (this.mobilePhone.startsWith('0')) {
          this.mobilePhone = this.mobilePhone.substring(1);
        }
    }
    if(checkPhoneValidaty){ 
    phoneValidaty({
      countryCode: this.contactCountryCode,
      mobileNumber: this.contactMobileCountry
    }).then((result) => {
      if (result == false) {
        this.contactPhoneInvalid = true;
        this.showToast(
          "Error",
          "Invalid contact phone number format. Please ensure the phone number matches the standard format for the selected country !",
          "error"
        );
      }
    });
  }
    
  }
  async handlePhoneValidaty() {
    if(this.mobilePhone != null && this.mobilePhone != '' && this.mobilePhone != undefined){
      this.contactPhoneInvalid = false;
       const isValid = (/^05\d{8}$/.test(this.mobilePhone) || /^\d{9}$/.test(this.mobilePhone));

        if (!isValid) {
          this.contactPhoneInvalid = true;
          this.showToast(
            "Error",
            "Mobile number must be 9 digits or 10 digits starting with '05', with no spaces or special characters.",
            "error"
          );
          return false;
        }
        // Remove leading zero if present
        if (this.mobilePhone.startsWith('0')) {
          this.mobilePhone = this.mobilePhone.substring(1);
        }
    }
    
    return phoneValidaty({
      countryCode: this.countryCode,
      mobileNumber: this.mobilePhone
    }).then((result) => {
      if (result === false) {
        this.contactPhoneInvalid = true;
        this.showToast(
          "Error",
          "Invalid phone number format. Please ensure the phone number matches the standard format for the selected country!",
          "error"
        );
        return false;
      }
      this.contactPhoneInvalid = false;
      return true;
    });
  }

  async handleAccDuplicateCheck() {
    console.log("In the duplicate page ");
    try {
      const data = await accDuplicateCheck({
        email: this.accEmail,
        emiratesNo: this.emiratesNo,
        passportNo: this.accPasspNo,
        mobilePhone: this.mobilePhone,
        accType: this.accountTypeSelectedLabel,
        registrationNo: this.accRegisNo
      });

      if (data) {
        this.showToast(
          "Error",
          "This Account already exists with similar values",
          "error"
        );
      }

      console.log("data", data);
      return data;
    } catch (error) {
      console.error("Error in duplicate check:", error);
      // Handle any errors here if needed
      return null; // or handle appropriately
    }
  }
  async handleContactDuplicateCheck() {
    console.log("In the duplicate contact page ");
    try {
      const data = await contactDuplicateCheck({
        mobilePhone: this.contactMobileCountry,
        Firstname: this.contactFirstName,
        lastName: this.contactLastName,
        isPerson: this.isPerson,
        accountId: this.accountId
      });

      if (data) {
        this.showToast(
          "Error",
          "This Contact already exists with similar values",
          "error"
        );
      }

      console.log("data", data);
      return data;
    } catch (error) {
      console.error("Error in duplicate check:", error);
      // Handle any errors here if needed
      return null; // or handle appropriately
    }
  }

  handleUploadFinished(event) {
    this.uploadedFiles = event.detail.files;
    this.uploadedFiles.forEach((doc) => {
      console.log("dd", doc.documentId);
      this.uploadDocIds.push(doc.documentId);
    });
    console.log("FILES", this.uploadDocIds);
    // this.uploadedFiles = [...this.uploadedFiles, ...event.detail.files];
  }
  handleSubVerticalBlur(event) {
    // console.log('filtered'+JSON.stringify(this.subVerticalFilteredOptions));
    // console.log('event value'+event.currentTarget.value);
    console.log("event value" + event.target.value);

    // console.log('BLUR : ',JSON.stringify(this.subVerticalFilteredOptions).indexOf(event.currentTarget.value));
    const relatedTarget = event.relatedTarget; // The next focused element
    // console.log('event.relatedTarget.tagName: '+event.relatedTarget.class);
    console.log("related target:" + relatedTarget);
    if (relatedTarget)
      console.log(
        "event.relatedTarget.tagName: " + event.relatedTarget.tagName
      );

    if (relatedTarget && relatedTarget.tagName === "DIV") {
      // If the new focused element is an <li>, do not close the dropdown
      return;
    }
    if (
      JSON.stringify(this.subVerticalFilteredOptions).indexOf(
        '"' + event.target.value + '"'
      ) == -1
    ) {
      console.log("entered in the cleaf");
      this.subVerticalSelectedValue = "";
      this.clearSubVerticalInput();
    }
  }
  handleCategoryBlur(event) {
    // console.log('BLUR category: ',JSON.stringify(this.categoryFilteredOptions).indexOf('"'+event.target.value+'"'));
    console.log("event value" + event.target.value);
    // console.log('dataset value'+event.Target.dataset.value);

    // console.log( 'BLUR category Filtered: ',JSON.stringify(this.categoryFilteredOptions));

    const relatedTarget = event.relatedTarget; // The next focused element
    // console.log('event.relatedTarget.tagName: '+event.relatedTarget.class);

    if (relatedTarget && relatedTarget.tagName === "DIV") {
      // If the new focused element is an <li>, do not close the dropdown
      return;
    }
    if (
      JSON.stringify(this.categoryFilteredOptions).indexOf(
        '"' + event.target.value + '"'
      ) == -1
    ) {
      this.caseCategorySelectedValue = "";
      this.clearCategoryInput();
    }
  }
  handleSubCategoryBlur(event) {
    // console.log('BLUR category: ',JSON.stringify(this.categoryFilteredOptions).indexOf('"'+event.target.value+'"'));
    console.log("event value" + event.target.value);
    // console.log('dataset value'+event.Target.dataset.value);

    // console.log( 'BLUR category Filtered: ',JSON.stringify(this.categoryFilteredOptions));

    const relatedTarget = event.relatedTarget; // The next focused element
    // console.log('event.relatedTarget.tagName: '+event.relatedTarget.class);

    if (relatedTarget && relatedTarget.tagName === "DIV") {
      // If the new focused element is an <li>, do not close the dropdown
      return;
    }
    if (
      JSON.stringify(this.subCategoryFilteredOptions).indexOf(
        '"' + event.target.value + '"'
      ) == -1
    ) {
      this.subCategorySelectedValue = "";
      //  if (this.isMaintenance) this.clearSubCategoryInput();
      // else {
      this.clearSubCategoryInputNoReq();
      // }
    }
  }
  handleObjectCategoryBlur(event) {
    // console.log('BLUR category: ',JSON.stringify(this.categoryFilteredOptions).indexOf('"'+event.target.value+'"'));
    console.log("event value" + event.target.value);
    // console.log('dataset value'+event.Target.dataset.value);

    // console.log( 'BLUR category Filtered: ',JSON.stringify(this.categoryFilteredOptions));

    const relatedTarget = event.relatedTarget; // The next focused element
    // console.log('event.relatedTarget.tagName: '+event.relatedTarget.class);

    if (relatedTarget && relatedTarget.tagName === "DIV") {
      // If the new focused element is an <li>, do not close the dropdown
      return;
    }
    if (
      JSON.stringify(this.objectCategoryFilteredOptions).indexOf(
        '"' + event.target.value + '"'
      ) == -1
    ) {
      // this.objectCategorySelectedValue = "";
      this.clearobjectCategoryInput();
    }
  }
  handleCompanyChoiceBlue(event) {
    console.log("event value" + event.target.value);
    const relatedTarget = event.relatedTarget; // The next focused element
    // console.log('event.relatedTarget.tagName: '+event.relatedTarget.class);

    if (relatedTarget && relatedTarget.tagName === "DIV") {
      // If the new focused element is an <li>, do not close the dropdown
      return;
    }
    // console.log('BLUR company: ',JSON.stringify(this.companyFilteredOptions).indexOf('"'+event.target.value+'"'));
    if (
      JSON.stringify(this.companyFilteredOptions).indexOf(
        '"' + event.target.value + '"'
      ) == -1
    ) {
      this.companySelectedValue = "";
      this.clearCompanyInput();
    }
  }
}