---
author: mugithi
comments: true
date: 2013-01-12 02:11:58+00:00
layout: post
#link: https://fvtool.wordpress.com/2013/01/12/python-beginings/
slug: python-beginings
title: Python - beginings
wordpress_id: 189
tags:
- python
---

I have always wanted to use python for my scripting and especially for manipulating lists and such, but I always find it took too much time and I am much better with excel to manipulate lists. But not tonight.

So todays problem was to change a column list to a horizontal list. I had bunch of licenses and an extra 10 mins in my hand that i squandered doing this.. I started with a license file file containing 


    
    <code>→ cat license
    a_sis			MTVVGAF		Deduplication (Advanced Single-Instance Storage)
    cifs			DZDACHD		CIFS protocol
    compression		CEVIVFK		Compression
    disk_sanitization	PZKEAZL		Disk sanitization
    http			NAZOMKC		HTTP protocol
    fcp			BKHEXNB		Works but does not provide much functionality - use iSCSI
    flex_cache_nfs		ADIPPVM		FlexCache license
    flex_clone		ANLEAZL		FlexClone license
    iscsi			BSLRLTG		iSCSI protocol
    nearstore_option	ELNRLTG		NearStore personality
    nfs			BQOEAZL		NFS protocol
    operations_manager	CYLGWWF		Operations manager
    protection_manager	CGUKRDE		Protection manager
    provisioning_manager	UYNXFJJ		Provisioning manager
    smdomino		RKBAFSN		SnapManager for Domino*
    smsql			HNGEAZL		SnapManager for SQL Server*
    snaplock		ZOJPPVM		SnapLock WORM Compliance edition
    snaplock_enterprise	PTZZESN		SnapLock WORM Enterprise edition
    snapmanagerexchange	BCJEAZL		SnapManager for Exchange*
    snapmanager_hyperv	COIRLTG		SnapManager for Hyper-V
    snapmanager_oracle	QZJTKCL		SnapManager for Oracle
    snapmanager_sap		WICPMKC		SnapManager for SAP
    snapmanager_sharepoint	UPDCBQH		SnapManager for SharePoint
    snapmirror		DFVXFJJ		SnapMirror between simulators
    snapmirror_sync		XJQIVFK		Synchronous SnapMirror between simulators
    snaprestore		DNDCBQH		SnapRestore
    snapvalidator		JQAACHD		Oracle SnapValidator license
    sv_linux_pri		ZYICXLC		Open Systems SnapVault from Linux clients*
    sv_ontap_pri		PVOIVFK		SnapVault "primary" (source filer)
    sv_ontap_sec		PDXMQMI		SnapVault "secondary" (destination filer)
    sv_unix_pri		RQAYBFE		Open Systems SnapVault from UNIX clients*
    sv_windows_pri		ZOPRKAM		Open Systems SnapVault from Windows clients*
    syncmirror_local	RIQTKCL		SyncMirror (think RAID 4+1)
    vfiler			NQBYFJJ		Multiple virtual Filers
    vld			JGFRLTG		
    </code>

                                                                                                                                                                                                                                                                                                                                                                           

Sorting out just the licenses with awk

    
    <code>mymac: /tmp                                                                                                                                                                                                                                                                                                                                             
    → cat license | awk '{print $2}' > license2
    MTVVGAF
    DZDACHD
    CEVIVFK
    PZKEAZL
    NAZOMKC
    BKHEXNB
    ADIPPVM
    ANLEAZL
    BSLRLTG
    ELNRLTG
    BQOEAZL
    CYLGWWF
    CGUKRDE
    UYNXFJJ
    RKBAFSN
    HNGEAZL
    ZOJPPVM
    PTZZESN
    BCJEAZL
    COIRLTG
    QZJTKCL
    WICPMKC
    UPDCBQH
    DFVXFJJ
    XJQIVFK
    DNDCBQH
    JQAACHD
    ZYICXLC
    PVOIVFK
    PDXMQMI
    RQAYBFE
    ZOPRKAM
    RIQTKCL
    NQBYFJJ
    JGFRLTG
    </code>


I then switched to python

    
    <code>
    mymac: /tmp                                                                                                                                                                                                                                                                                                                                             
    → python
    Python 2.7.2 (default, Jun 20 2012, 16:23:33) 
    [GCC 4.2.1 Compatible Apple Clang 4.0 (tags/Apple/clang-418.0.60)] on darwin
    Type "help", "copyright", "credits" or "license" for more information.
    </code>


I opened the file

    
    <code>>>> f = open('/tmp/license2', 'r')
    </code>

I read the file and assigned to a variable called temp

    
    <code>>>> temp = f.read()
    >>> temp
    'MTVVGAF\nDZDACHD\nCEVIVFK\nPZKEAZL\nNAZOMKC\nBKHEXNB\nADIPPVM\nANLEAZL\nBSLRLTG\nELNRLTG\nBQOEAZL\nCYLGWWF\nCGUKRDE\nUYNXFJJ\nRKBAFSN\nHNGEAZL\nZOJPPVM\nPTZZESN\nBCJEAZL\nCOIRLTG\nQZJTKCL\nWICPMKC\nUPDCBQH\nDFVXFJJ\nXJQIVFK\nDNDCBQH\nJQAACHD\nZYICXLC\nPVOIVFK\nPDXMQMI\nRQAYBFE\nZOPRKAM\nRIQTKCL\nNQBYFJJ\nJGFRLTG\n'
    </code>


I split the string at \n and assigned it to variable temp2

    
    <code>>>> temp2 = temp.split('\n')
    >>> temp2
    ['MTVVGAF', 'DZDACHD', 'CEVIVFK', 'PZKEAZL', 'NAZOMKC', 'BKHEXNB', 'ADIPPVM', 'ANLEAZL', 'BSLRLTG', 'ELNRLTG', 'BQOEAZL', 'CYLGWWF', 'CGUKRDE', 'UYNXFJJ', 'RKBAFSN', 'HNGEAZL', 'ZOJPPVM', 'PTZZESN', 'BCJEAZL', 'COIRLTG', 'QZJTKCL', 'WICPMKC', 'UPDCBQH', 'DFVXFJJ', 'XJQIVFK', 'DNDCBQH', 'JQAACHD', 'ZYICXLC', 'PVOIVFK', 'PDXMQMI', 'RQAYBFE', 'ZOPRKAM', 'RIQTKCL', 'NQBYFJJ', 'JGFRLTG', '']
    </code>


I joined my now delimited list using a space

    
    <code>>>> temp3 = ' '.join(temp2)
    >>> temp3
    'MTVVGAF DZDACHD CEVIVFK PZKEAZL NAZOMKC BKHEXNB ADIPPVM ANLEAZL BSLRLTG ELNRLTG BQOEAZL CYLGWWF CGUKRDE UYNXFJJ RKBAFSN HNGEAZL ZOJPPVM PTZZESN BCJEAZL COIRLTG QZJTKCL WICPMKC UPDCBQH DFVXFJJ XJQIVFK DNDCBQH JQAACHD ZYICXLC PVOIVFK PDXMQMI RQAYBFE ZOPRKAM RIQTKCL NQBYFJJ JGFRLTG '
    </code>



Voila, I now had my string to copy paste in my command license add command
