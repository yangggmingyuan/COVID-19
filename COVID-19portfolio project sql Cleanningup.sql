/*

Cleaning Data in SQL Queries

*/


Select *
From portofolio_project..NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------
--1.
-- Standardize Date Format


Select saleDateConverted, CONVERT(Date,SaleDate)
From portofolio_project..NashvilleHousing


Update portofolio_project..NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE portofolio_project..NashvilleHousing
Add SaleDateConverted Date;

Update portofolio_project..NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------
--2.
-- Populate Property Address data

Select *
From portofolio_project..NashvilleHousing
--Where PropertyAddress is null
order by ParcelID



Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From portofolio_project..NashvilleHousing a
JOIN portofolio_project..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From portofolio_project..NashvilleHousing a
JOIN portofolio_project..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------
--3.
-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From portofolio_project..NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From portofolio_project..NashvilleHousing



ALTER TABLE portofolio_project..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update portofolio_project..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE portofolio_project..NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update portofolio_project..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




Select *
From portofolio_project..NashvilleHousing






Select OwnerAddress
From portofolio_project..NashvilleHousing


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From portofolio_project..NashvilleHousing



ALTER TABLE portofolio_project..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update portofolio_project..NashvilleHousing

SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE portofolio_project..NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update portofolio_project..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE portofolio_project..NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update portofolio_project..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



Select *
From portofolio_project..NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------

--4.
-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From portofolio_project..NashvilleHousing
Group by SoldAsVacant
order by 2




Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From portofolio_project..NashvilleHousing


Update portofolio_project..NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END






-----------------------------------------------------------------------------------------------------------------------------------------------------------
--5.
-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From portofolio_project..NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress



Select *
From portofolio_project..NashvilleHousing

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From portofolio_project..NashvilleHousing


ALTER TABLE portofolio_project..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
