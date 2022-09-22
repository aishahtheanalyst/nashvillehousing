-- cleaning data for exploration

select *
from nashvillehousing
where PropertyAddress is null;

-- standardise date format

select saledate, convert(saledate, date)
from nashvillehousing;

update nashvillehousing
set saledate = convert(saledate, date);

-- populate property address data

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull (a.PropertyAddress, b.PropertyAddress)
from nashvillehousing a
join nashvillehousing b
on a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;

update nashvillehousing a
join nashvillehousing b
on a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID
set a.propertyaddress = ifnull (a.propertyaddress, b.propertyaddress)
where a.propertyaddress is null;

-- separating address into individual columns (address, city, state)
-- PropertyAddress

select PropertyAddress
from nashvillehousing;

select substring(PropertyAddress, 1, (locate(',', PropertyAddress) -1 )) as address,
substring(PropertyAddress, (locate(',', PropertyAddress) +1), length(PropertyAddress)) as city
from nashvillehousing; -- finding the comma and separating address and city, whilst simultaneously omitting comma from query

alter table nashvillehousing
add PropertySplitAddress nvarchar(255); 

update nashvillehousing
set PropertySplitAddress = substring(PropertyAddress, 1, (locate(',', PropertyAddress) -1 ));

alter table nashvillehousing
add PropertySplitCity nvarchar(255);

update nashvillehousing
set PropertySplitCity = substring(PropertyAddress, (locate(',', PropertyAddress) +1), length(PropertyAddress));

-- OwnerAddress

select OwnerAddress
from nashvillehousing;

select substring(OwnerAddress, 1, (locate(',', OwnerAddress) -1 )) as address
from nashvillehousing; -- address

-- have not found a solution for city yet

select substring(OwnerAddress, (locate('TN', OwnerAddress) -1), length(OwnerAddress)) as state
from nashvillehousing;

-- change Y and N to Yes and No in "Sold As Vacant" field

select distinct(SoldAsVacant), count(SoldAsVacant)
from nashvillehousing
group by SoldAsVacant
order by 2;

select SoldAsVacant
, case 
when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end
from nashvillehousing;

update nashvillehousing
set soldasvacant = case 
when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end;

-- remove duplicates 

with rownumcte as (
select *,
row_number() over ( partition by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
order by UniqueID) row_num
from nashvillehousing)
delete from nashvillehousing
using nashvillehousing
join rownumcte
on nashvillehousing.parcelid = rownumcte.parcelid
where row_num > 1;

-- delete unused columns

alter table nashvillehousing
drop column OwnerAddress; -- TaxDistrict, PropertyAddress, SaleDate