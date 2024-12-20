/*
 What key metrics would you propose to monitor over time the success of the team's efforts in improving the guest host matching process and why?
 Clearly define your metric(s) and explain how each is computed
*/

-- Key Metric 1
-- Success rate of enquires - (No. of enquires that led to booking) / (Total no. of enquires)
-- If this metric improves over time that means more no. of enquires are resulting in booking thereby improving guest-host matching process.
-- we can compare this metric month-wise, eg. By how much percent success rate has increased/decreased this month compared to previous month.

-- overall success rate - 41.55
select
    round(avg(case when ts_booking_at is not null then 1 else 0 end) * 100, 2)
from contacts;



-- Key Metric 2
-- Average host acceptance rate in Rio de Janeiro
-- Average of (No. of enquires that the host accepts) / (Total no. of enquires) for all the hosts.
-- If this improves over time, that means on an average hosts are accepting more no. of enquires leading to more bookings thereby contributing to guest host matching process.

-- result - 53.15
with cte as (select
    id_host_anon,
    avg(case when ts_accepted_at_first is not null then 1 else 0 end) * 100 as acceptance_rate
from contacts
group by 1)
select
    round(avg(acceptance_rate), 2)
from cte;



-- Key Metric 3
-- Post acceptance drop-off rate - (No of accepted enquires that did not led to booking) / (Total no of accepted enquires)
-- If this decreases over time, that means more no of accepted enquires are resulting in booking thereby improving guest-host matching process.
-- This metric can be used to study the efficiency of accepted enquires for booking

-- result - 29.41
select
    round(avg(case when ts_booking_at is null then 1 else 0 end) * 100, 2)
from contacts
where ts_accepted_at_first is not null;

-- Key Metric 4
-- Average no. of new guests on airbnb each month
-- If this metric improves over time, that means more no. of new guests enquiring about listings each month,
-- i.e. more no of enquires which indirectly leads to more booking thereby contributing to guest-host matching process

-- result - This means that on an average about 2274 new guests enquire about the listings in Rio de janeiro each month.
WITH cte as (select
    to_char(ts_interaction_first, 'YYYY-MM') as month,
    count(distinct id_guest_anon) as no_of_new_guests
from contacts
where guest_user_stage_first = 'new'
group by 1)
select
    round(avg(no_of_new_guests))
from cte;


/*
 What areas should we invest in to increase the number of successful bookings in Rio de Janeiro?
 What segments are doing well and what could be improved?
 Propose 2-3 specific recommendations (business initiatives and product changes) that could address these opportunities.
 Demonstrate rationale behind each recommendation AND prioritize your recommendations in order of their estimated impact
*/


with cte as (select
    contact_channel_first,
    round(avg(case when ts_booking_at is not null then 1 else 0 end) * 100, 2) overall_success_rate_of_enquires,
    count(*) no_of_enquires,
    round(avg(case when ts_accepted_at_first is not null then 1 else 0 end) * 100, 2) acceptance_rate
from contacts
group by 1),
cte2 as (select
    sum(no_of_enquires) as total_enquires
from cte),
t1 as (select
    contact_channel_first,
    overall_success_rate_of_enquires,
    acceptance_rate,
    round(no_of_enquires / (select total_enquires from cte2), 2) * 100 as enquiry_percentage
from cte),
t2 as (
    select
    contact_channel_first,
    round(avg(case when ts_booking_at is null then 1 else 0 end) * 100, 2) as drop_off_rate,
    round(avg(case when ts_booking_at is not null then 1 else 0 end) * 100, 2) as success_rate_of_accepted_enquires
from contacts
where ts_accepted_at_first is not null
group by 1
)
select
    t1.contact_channel_first,
    t1.overall_success_rate_of_enquires,
    t1.enquiry_percentage,
    t1.acceptance_rate,
    t2.success_rate_of_accepted_enquires,
    t2.drop_off_rate
from t1
inner join t2
on t1.contact_channel_first = t2.contact_channel_first;

/*
 Now from the given statistics,
 About 46% of the enquires for booking is through contact_me option
 Out of which only ~42% of them are accepted by the host and rest of them are rejected
 Now out of those ~42%, only ~17% result in booking, and ~83% are dropped of by the guests.

 To improve the guest-host matching process,
 1. Hosts need to accept more no of enquires (increasing host acceptance rate)
 2. Guests also need to book more after being approved by the host (decreasing the drop-off rate)

 For this there are few suggestions,
 1. we can setup a reward system to motivate guests and host to promote bookings
    such that everytime a host accepts an enquiry for booking he/she gets a reward point
    similarly everytime a guest books a listing, they get a reward point.
    Reward points can later be converted into cashback that benefit guests or trending time period for listings that benefit hosts.
 */

-- what effect does delay in acceptance have on drop-off rate
select
    case when age(ts_accepted_at_first, ts_interaction_first) <= interval '1 hour' then '<= 1 hour'
        when age(ts_accepted_at_first, ts_interaction_first) <= interval '12 hour' then '<= 12 hour'
        when age(ts_accepted_at_first, ts_interaction_first) <= interval '1 day' then '<= 1 day'
        when age(ts_accepted_at_first, ts_interaction_first) <= interval '3 day' then '<= 3 day'
        when age(ts_accepted_at_first, ts_interaction_first) <= interval '1 week' then '<= 1 week'
    else '> 1 week' end as time_difference,
    round(avg(case when ts_booking_at is null then 1 else 0 end) * 100, 2)
from contacts
where ts_accepted_at_first is not null
group by 1
order by 2;

/*
 As you can see that,
 when the host accepts the enquiry for booking within 1 hour, least no. of guests drops off from booking after being accepted
 but this drop-off percentage increases gradually when the host takes longer period of time to accept.
 */

-- what effect does delay in reply have on success rate of bookings
select
    case when age(ts_reply_at_first, ts_interaction_first) <= interval '1 hour' then '<= 1 hour'
        when age(ts_reply_at_first, ts_interaction_first) <= interval '12 hour' then '<= 12 hour'
        when age(ts_reply_at_first, ts_interaction_first) <= interval '1 day' then '<= 1 day'
        when age(ts_reply_at_first, ts_interaction_first) <= interval '3 day' then '<= 3 day'
        when age(ts_reply_at_first, ts_interaction_first) <= interval '1 week' then '<= 1 week'
    else '> 1 week' end as time_difference,
    round(avg(case when ts_booking_at is not null then 1 else 0 end) * 100, 2)
from contacts
where ts_reply_at_first is not null
group by 1
order by 2 desc;

/*
 As you can see that
 About 64% of enquires result in successful booking when the host replies within 1 hour of the enquiry,
 and this rate of successful booking drops drastically when host takes longer period of time to reply.
 */


-- From the insights above it clearly shows that,
-- the host must quickly reply and accept the enquiry for to increase the booking success and reduce drop-off rates

/*
 2. Now to motivate hosts to reply and accept quickly,
    we should implement a strategy for hosts based on their responsiveness such that
    if a host responds late to an enquiry it can reduce its visibility on the platform (or its listings visibility)
    but if the host replies promptly it can increase its visibility (which indirectly promotes business).
 */


with cte as (select
    l.room_type as room_type,
    count(*) as no_of_enquires,
    round(avg(case when ts_booking_at is not null then 1 else 0 end) * 100, 2) as booking_rate
from listings l
inner join contacts c
on l.id_listing_anon = c.id_listing_anon
group by 1),
cte2 as (select
    count(*) as total_enquires
from contacts)
select
    room_type,
    round((no_of_enquires / (select total_enquires::numeric from cte2)) * 100, 2) as percent_enquires,
    booking_rate
from cte;

/*
 From the statistics above,
 1. About 75% of the enquires are for entire home/apt making it the most popular choice,
    but in terms of booking it lags behind private room for which rate of successful booking is the highest.

 2. Shared rooms struggle in terms of popularity and bookings with only 32% of successful booking rate out of 2% enquires.

 Now we should focus more on
 1. Improving the popularity of shared rooms, this can be done by highlighting (or increasing the visibility) shared rooms by setting it as the default choice for room_type
 2. And for the most popular option, its booking rate i.e. we can offer discounts on highly priced listings to enable guests to book more.
 */