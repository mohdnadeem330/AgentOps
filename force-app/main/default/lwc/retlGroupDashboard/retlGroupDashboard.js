import { LightningElement, api, wire, track } from 'lwc';
import getActiveOrderCount from '@salesforce/apex/RETL_AccountMetricsController.getActiveOrderCount';
import getRevenueMetrics from '@salesforce/apex/RETL_AccountMetricsController.getRevenueMetrics';
import getExpiringLeasesCount from '@salesforce/apex/RETL_AccountMetricsController.getExpiringLeasesCount';
import getTotalContractedArea from '@salesforce/apex/RETL_AccountMetricsController.getTotalContractedArea';
import getOrderNames from '@salesforce/apex/RETL_AccountMetricsController.getOrderNames';
import getActiveCaseCount from '@salesforce/apex/RETL_AccountMetricsController.getActiveCaseCount';
import getActiveCaseSubjects from '@salesforce/apex/RETL_AccountMetricsController.getActiveCaseSubjects';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Account.Type';
import ACCOUNT_CURRENCY_FIELD from '@salesforce/schema/Account.CurrencyIsoCode';
import CASE_CATEGORY_FIELD from '@salesforce/schema/Case.RETL_SR_Category__c'
import getCustomerAccountCount from '@salesforce/apex/RETL_AccountMetricsController.getCustomerAccountCount';
import getCustomerAccounts from '@salesforce/apex/RETL_AccountMetricsController.getCustomerAccounts';
import getBrandsViaJunction from '@salesforce/apex/RETL_ChildAccountsController.getBrandsViaJunction';

const AED_FORMATTER = new Intl.NumberFormat('en-AE', {
    style: 'currency',
    currency: 'AED',
    currencyDisplay: 'symbol',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
});

export default class GroupDashboard extends LightningElement {
    @api recordId;
    @track accountName;
    @track accountType;
    @track accountCurrencyIsoCode;
    // Derive current currency code by type:
    get currentCurrencyCode() {
        // If account type equals 'Group' keep AED, else use account currency when present
        if ((this.accountType || '').toLowerCase() === 'group') return 'AED';
        return this.accountCurrencyIsoCode || 'AED';
    }

    // Dynamic currency formatter using Intl.NumberFormat. Falls back gracefully.
    formatCurrency(amount, currencyCode = this.currentCurrencyCode) {
        const n = Number(amount);
        const code = currencyCode || 'AED';
        if (!Number.isFinite(n)) {
            try {
                return new Intl.NumberFormat(undefined, { style: 'currency', currency: code, minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(0);
            } catch (e) {
                return `${code} ${Number(0).toFixed(2)}`;
            }
        }
        try {
            return new Intl.NumberFormat(undefined, { style: 'currency', currency: code, minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
        } catch (e) {
            const v = Number.isFinite(n) ? n : 0;
            return `${code} ${v.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
        }
    }

    // Number-only formatter with thousand separators (2 decimals)
    formatNumber2(amount) {
        const n = Number(amount);
        if (!Number.isFinite(n)) return '0.00';
        try {
            return new Intl.NumberFormat('en-AE', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
        } catch (e) {
            const v = Number.isFinite(n) ? n : 0;
            return v.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        }
    }

    @track orderCount = 0;
    @track _monthlySales = 0;
    @track _annualSales = 0;
    @track totalArea = 0;
    @track expiringLeases = 0;
    @track caseCount = 0;
    @track customerCount = 0;
    @track brandCount = 0;

    @track orderData = [];
    @track caseData = [];
    @track customerAccountData = [];
    @track brandAccountData = [];
    @track allBrandAccounts = []; // Store all brand accounts for "View All"

    // Modal visibility flags
    @track isOrderModalOpen = false;
    @track isCaseModalOpen = false;
    @track isCustomerModalOpen = false;
    @track isBrandModalOpen = false;

    connectedCallback() {
        this.fetchMetrics();
    }

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD, ACCOUNT_TYPE_FIELD, ACCOUNT_CURRENCY_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = data.fields.Name.value;
            this.accountType = data.fields.Type && data.fields.Type.value;
            // CurrencyIsoCode is available when Multi-Currency is enabled
            this.accountCurrencyIsoCode = data.fields.CurrencyIsoCode && data.fields.CurrencyIsoCode.value;
        } else if (error) {
            console.error('Error fetching account details:', error);
        }
    }

    fetchMetrics() {
        getActiveOrderCount({ accountId: this.recordId })
            .then(result => this.orderCount = result)
            .catch(console.error);

        getRevenueMetrics({ accountId: this.recordId })
            .then(result => {
                this._monthlySales = result.monthlySales || 0;
                this._annualSales = result.annualSales || 0;
                this.totalArea = result.totalArea || 0;
                this.expiringLeases = result.expiringLeases || 0;
            })
            .catch(console.error);

        getOrderNames({ accountId: this.recordId })
    .then(result => {
        this.orderData = result.map(order => ({
            ...order,
            recordLink: `/lightning/r/${order.attributes?.type}/${order.Id}/view`
        }));
    })
    .catch(console.error);


        getActiveCaseCount({ accountId: this.recordId })
            .then(result => this.caseCount = result)
            .catch(console.error);

        getActiveCaseSubjects({ accountId: this.recordId })
            .then(result =>{
                 this.caseData = result.map(cs => ({
                ...cs,
             recordLink: `/lightning/r/${cs.attributes?.type}/${cs.Id}/view`,
              orderLink: cs.RETL_SR_Order__c
                ? `/lightning/r/Order/${cs.RETL_SR_Order__c}/view`
                : null
        }));
            })
            .catch(console.error);



        getCustomerAccountCount({ accountId: this.recordId })
            .then(result => this.customerCount = result)
            .catch(console.error);

        getCustomerAccounts({ accountId: this.recordId })
            .then(result => {
                this.customerAccountData = result.map(cust => ({
                    ...cust,
                    recordLink: `/lightning/r/${cust.attributes?.type}/${cust.Id}/view`
                }));
            })
            .catch(console.error);

     
    

       getBrandsViaJunction({ groupId: this.recordId })
    .then(result => {
        this.brandCount = result.brandCount;
        this.allBrandAccounts = result.brandRecords.map(brand => ({
            ...brand,
            recordLink: `/lightning/r/${brand.attributes?.type}/${brand.Id}/view`,
            logoUrl: brand.RETL_Logo_Url__c
        }));

        // Filter brands to show only Name and AccountNumber if Type = 'Customer'
        this.brandAccountData = this.allBrandAccounts.slice(0, 5).map(brand => {
            if (brand.Type === 'Customer') {
                return {
                    Id: brand.Id,
                    Name: brand.Name,
                    AccountNumber: brand.AccountNumber,
                    recordLink: brand.recordLink
                };
            }
            return brand;
        });

    })
    .catch(console.error);
    }

    // ----- MODAL CONTROL -----
    openOrderModal() {
        this.isOrderModalOpen = true;
    }
    closeOrderModal() {
        this.isOrderModalOpen = false;
    }


    openCaseModal() {
        this.isCaseModalOpen = true;
    }
    closeCaseModal() {
        this.isCaseModalOpen = false;
    }

    openCustomerModal() {
        this.isCustomerModalOpen = true;
    }
    closeCustomerModal() {
        this.isCustomerModalOpen = false;
    }

    openBrandModal() {
        this.isBrandModalOpen = true;
    }
    closeBrandModal() {
        this.isBrandModalOpen = false;
    }

    // Filter allBrandAccounts to show only Name and AccountNumber if Type = 'Customer'
    get filteredBrandAccounts() {
        return this.allBrandAccounts.map(brand => {
            if (brand.Type === 'Customer') {
                return {
                    Id: brand.Id,
                    Name: brand.Name,
                    AccountNumber: brand.AccountNumber,
                    recordLink: brand.recordLink
                };
            }
            return brand;
        });
    }

    

    // ----- TABLE COLUMNS -----
    orderColumns = [
        { label: 'Lease Number', fieldName: 'OrderNumber' },
        { label: 'Start Date', fieldName: 'EffectiveDate', type: 'date' },
        { label: 'End Date', fieldName: 'EndDate', type: 'date' },
        {
            label: 'Rent Per Month',
            fieldName: 'RETL_Rent_Per_Month__c',
            type: 'text',
            cellAttributes: { alignment: 'left' },
            typeAttributes: {}
        }
    ];

    caseColumns = [
        { label: 'Case Number', fieldName: 'CaseNumber' },
        { label: 'Status', fieldName: 'Status' },
        { label: 'SR Category', fieldName: 'RETL_SR_Category__c' },
        { label: 'Contract', fieldName: 'Contract__c' }
    ];

    accountColumns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Account Number', fieldName: 'AccountNumber' }
    ];


    orderLink(order) {
        return `/lightning/r/${order.attributes?.type}/${order.Id}/view`;
    }

    // Provide formatted rows for orders with currency on rent column (uses currentCurrencyCode)
    get orderData() {
        return (this._orderData || []).map(o => ({
            ...o,
            RETL_Rent_Per_Month__c: this.formatCurrency(o.RETL_Rent_Per_Month__c)
        }));
    }
    set orderData(val) {
        this._orderData = val;
    }

    // Formatted getters for UI using dynamic currency
    get monthlySales() {
        return this.formatCurrency(this._monthlySales);
    }

    get annualSales() {
        return this.formatCurrency(this._annualSales);
    }
}