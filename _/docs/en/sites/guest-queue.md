# Guest waiting queue (antrian)
path: both

Use a numbered queue when guests wait for service at a counter or room — not the kitchen order screen.

## When to use it

Turn this on for clinics, service desks, or any line where guests take a number and staff call the next person.

## In chat

Ask: "Enable guest queue on my site and add a queue block for the front desk."

Home uses the **inst.site.queue** instructions to turn on the queue capability, create queues with `site.queue.put`, and remind you to publish.

## On the screen

1. Open your site in **Sites** → **Settings** and enable **Queue** (guest antrian).
2. Open **Queue** in the site editor. Add a queue, set the ticket prefix, guest form fields, and daily reset if you need it.
3. Add a **Queue** block on the page layout and **Publish**.
4. Staff open **Queue** → pick a queue → use **Call next** and mark tickets done or skipped.
5. Guests open the published page, tap the queue block, fill the form, and can follow their ticket on the track link.
