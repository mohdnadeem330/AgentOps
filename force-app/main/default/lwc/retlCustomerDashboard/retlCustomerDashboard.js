import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import getCustomerMetrics from '@salesforce/apex/RETL_AccountMetricsController.getCustomerMetrics';
import getCustomerExtras from '@salesforce/apex/RETL_AccountMetricsController.getCustomerExtras';
import getActiveLeaseRecords from '@salesforce/apex/RETL_AccountMetricsController.getActiveLeaseRecords';
import getOrderRevenueByCustomer from '@salesforce/apex/RETL_AccountMetricsController.getOrderRevenueByCustomer';
import getLinkedBrands from '@salesforce/apex/RETL_AccountMetricsController.getLinkedBrands';
import getTradeLicenses from '@salesforce/apex/RETL_AccountMetricsController.getTradeLicenses';
import getAccountCases from '@salesforce/apex/RETL_AccountMetricsController.getAccountCases';

const FIELDS = ['Account.Type', 'Account.Name'];

export default class retlCustomerDashboard extends LightningElement {
    @api recordId;

    accountType;
    accountName;

    @track activeLeases = 0;
    @track caseCount = 0;
    @track linkedBrands = 0;
    @track tradeLicenses = 0;

    @track monthlyRevenue = 0;
    @track annualRevenue = 0;

    get monthlyRevenueAED() {
        try {
            return new Intl.NumberFormat('en-AE', { style: 'currency', currency: 'AED', maximumFractionDigits: 2 }).format(this.monthlyRevenue || 0);
        } catch (e) {
            return `AED ${Number(this.monthlyRevenue || 0).toFixed(2)}`;
        }
    }

    get annualRevenueAED() {
        try {
            return new Intl.NumberFormat('en-AE', { style: 'currency', currency: 'AED', maximumFractionDigits: 2 }).format(this.annualRevenue || 0);
        } catch (e) {
            return `AED ${Number(this.annualRevenue || 0).toFixed(2)}`;
        }
    }
    @track contractedArea = 0;
    @track expiringLeases = 0;

    @track leaseOptions = [];
    @track selectedLeaseMetric = '';
    @track leaseData = [];

    @track brandOptions = [];
    @track selectedBrand = '';
    @track brandData = [];

    @track licenseOptions = [];
    @track selectedLicense = '';
    @track licenseData = [];

    @track caseOptions = [];
    @track selectedCase = '';
    @track caseData = [];

    @track brandLogoUrls = [
        'https://upload.wikimedia.org/wikipedia/commons/a/a6/Logo_NIKE.svg'
    ];

    // Modal controls
    @track showBrandModal = false;
    @track showLeaseModal = false;
    @track showLicenseModal = false;
    @track showCaseModal = false;

    get isCustomer() {
        return this.accountType === 'Customer';
    }

    // Column Definitions
    leaseColumns = [
        {
            label: 'Lease Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'OrderNumber' }, target: '_blank' }
        },
        { label: 'Effective Date', fieldName: 'EffectiveDate', type: 'date' },
        { label: 'End Date', fieldName: 'EndDate', type: 'date' },
        { label: 'Rent Per Month', fieldName: 'RETL_Rent_Per_Month__c', type: 'currency' }
    ];

    accountColumns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        { label: 'Status', fieldName: 'RETL_Status__c' },
        { label: 'Account Number', fieldName: 'AccountNumber' }
    ];

    caseColumns = [
        {
            label: 'Case Number',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'CaseNumber' }, target: '_blank' }
        },
        { label: 'SR Category', fieldName: 'RETL_SR_Category__c' },
        { label: 'Status', fieldName: 'Status' },
        {
            label: 'Lease',
            fieldName: 'leaseLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'leaseName' }, target: '_blank' }
        }
    ];

    brandColumns = [
        {
            label: 'Brand',
            fieldName: 'BrandLink',
            type: 'url',
            typeAttributes: { label: { fieldName: 'BrandName' }, target: '_blank' }
        },
        {
            label: 'Account Number',
            fieldName: 'AccountNumber'
        }
    ];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.accountType = data.fields.Type.value;
            this.accountName = data.fields.Name.value;
            if (this.isCustomer) {
                this.loadCustomerMetrics();
            }
        } else {
            console.error(error);
        }
    }

    async loadCustomerMetrics() {
        try {
        const results = await Promise.allSettled([
            getCustomerMetrics({ accountId: this.recordId }),
            getCustomerExtras({ accountId: this.recordId }),
            getAccountCases({ accountId: this.recordId }),
            getActiveLeaseRecords({ accountId: this.recordId }),
            getLinkedBrands({ accountId: this.recordId }),
            getTradeLicenses({ accountId: this.recordId }),
            getOrderRevenueByCustomer({ accountId: this.recordId })
        ]);

        const [metrics, extras, cases, leases, brands, licenses, revenue] = results.map(r => {
            if (r.status === 'fulfilled') {
                return r.value;
            } else {
                console.error('Apex call failed:', r.reason);
                return Array.isArray(r.reason) ? [] : {};
            }
        });

            // Metrics
            this.activeLeases = metrics.activeLeases || 0;
            this.linkedBrands = metrics.linkedBrands || 0;
            this.tradeLicenses = extras.tradeLicenseAccounts || 0;
            this.caseCount = cases.length || 0;

            this.monthlyRevenue = revenue.monthlyRevenue || 0;
            this.annualRevenue = revenue.annualRevenue || 0;
            this.contractedArea = revenue.totalArea || 0;
            this.expiringLeases = revenue.expiringLeases || 0;

            // Dropdown Options
            this.leaseOptions = [{ label: 'Select Lease', value: '' }, ...leases.map(l => ({
                label: l.Name__c || l.Name || 'Untitled Lease',
                value: l.Id
            }))];

            this.brandOptions = [{ label: 'Select Brand', value: '' }, ...brands.map(b => ({
                label: b.Name,
                value: b.Id
            }))];

            this.licenseOptions = [{ label: 'Select License', value: '' }, ...licenses.map(l => ({
                label: l.Name,
                value: l.Id
            }))];

            this.caseOptions = [{ label: 'Select Case', value: '' }, ...cases.map(c => ({
                label: c.CaseNumber,
                value: c.Id
            }))];

            // Data mapping with record links
            this.caseData = cases.map(c => ({
                ...c,
                RETL_SR_Category__c: c.RETL_SR_Category__c, // ensure field present for datatable
                leaseName: c.RETL_SR_Order__r?.Name || '',
                leaseLink: c.RETL_SR_Order__c ? `/lightning/r/Order/${c.RETL_SR_Order__c}/view` : '',
                recordLink: `/lightning/r/Case/${c.Id}/view`
            }));

            this.leaseData = leases.map(l => ({
                ...l,
                recordLink: `/lightning/r/Order/${l.Id}/view`
            }));

            this.licenseData = licenses.map(l => ({
                ...l,
                recordLink: `/lightning/r/Account/${l.Id}/view`
            }));

            this.brandData = brands.map(b => ({
                Id: b.Id,
                Name: b.Name,
                recordLink: `/lightning/r/RETL_Brand_Linkage__c/${b.Id}/view`,
                CustomerId: b.RETL_Customer__c,
                CustomerName: b.RETL_Customer__r?.Name,
                CustomerLink: b.RETL_Customer__c ? `/lightning/r/Account/${b.RETL_Customer__c}/view` : '',
                BrandId: b.RETL_Brand__c,
                BrandName: b.RETL_Brand__r?.Name,
                BrandLink: b.RETL_Brand__c ? `/lightning/r/Account/${b.RETL_Brand__c}/view` : '',
                AccountNumber: b.RETL_Brand__r?.AccountNumber,
                logoUrl: b.RETL_Brand__r?.RETL_Logo_Url__c
            }));
        } catch (err) {
            console.error('Error loading customer metrics:', err);
        }
    }

    // Dropdown Handlers
    handleLeaseChange(event) {
        this.selectedLeaseMetric = event.detail.value;
        getActiveLeaseRecords({ accountId: this.recordId })
            .then(res => {
                const mapped = res.map(l => ({
                    ...l,
                    recordLink: `/lightning/r/Lease__c/${l.Id}/view`
                }));
                this.leaseData = this.selectedLeaseMetric
                    ? mapped.filter(o => o.Id === this.selectedLeaseMetric)
                    : mapped;
            });
    }

    handleBrandChange(event) {
        this.selectedBrand = event.detail.value;
        getLinkedBrands({ accountId: this.recordId })
            .then(res => {
                const mapped = res.map(b => ({
                    Id: b.Id,
                    Name: b.Name,
                    Customer__c: b.Customer__c,
                    CustomerName: b.Customer__r?.Name,
                    CustomerLink: b.Customer__c ? `/lightning/r/Account/${b.Customer__c}/view` : '',
                    Brand__c: b.Brand__c,
                    BrandName: b.Brand__r?.Name,
                    BrandLink: b.Brand__c ? `/lightning/r/Account/${b.Brand__c}/view` : '',
                    AccountNumber: b.RETL_Brand__r?.AccountNumber
                }));
                this.brandData = this.selectedBrand
                    ? mapped.filter(b => b.Id === this.selectedBrand)
                    : mapped;
            });
    }

    handleLicenseChange(event) {
        this.selectedLicense = event.detail.value;
        getTradeLicenses({ accountId: this.recordId })
            .then(res => {
                const mapped = res.map(l => ({
                    ...l,
                    recordLink: `/lightning/r/Account/${l.Id}/view`
                }));
                this.licenseData = this.selectedLicense
                    ? mapped.filter(lc => lc.Id === this.selectedLicense)
                    : mapped;
            });
    }

    handleCaseChange(event) {
        this.selectedCase = event.detail.value;
        getAccountCases({ accountId: this.recordId })
            .then(res => {
                const mapped = res.map(c => ({
                    ...c,
                    RETL_SR_Category__c: c.RETL_SR_Category__c || '—',
                    leaseName: c.RETL_SR_Order__r?.Name || '',
                    leaseLink: c.RETL_SR_Order__c ? `/lightning/r/Order/${c.RETL_SR_Order__c}/view` : '',
                    recordLink: `/lightning/r/Case/${c.Id}/view`
                }));
                this.caseData = this.selectedCase
                    ? mapped.filter(c => c.Id === this.selectedCase)
                    : mapped;
            });
    }

    // Modal controls
    openBrandModal() {
        this.showBrandModal = true;
    }

    openLeaseModal() {
        this.showLeaseModal = true;
    }

    openLicenseModal() {
        this.showLicenseModal = true;
    }

    openCaseModal() {
        this.showCaseModal = true;
    }

    closeModals() {
        this.showBrandModal = false;
        this.showLeaseModal = false;
        this.showLicenseModal = false;
        this.showCaseModal = false;
    }

    get topFiveBrands() {
    return this.brandData.slice(0, 5);
}

}